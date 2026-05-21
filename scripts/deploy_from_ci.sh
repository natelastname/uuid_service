#!/usr/bin/env bash

# Deploy a specific commit from main using the image that CI built
# and pushed to ECR, then run a simple post-deploy smoke test.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -z "${AWS_ACCOUNT_ID:-}" ] || [ -z "${AWS_REGION:-}" ]; then
  echo "Please set AWS_ACCOUNT_ID and AWS_REGION environment variables."
  exit 1
fi

# Commit SHA to deploy. Defaults to the current HEAD in this repo.
COMMIT_SHA="${COMMIT_SHA:-$(git -C "${ROOT_DIR}" rev-parse HEAD)}"
ECR_REPOSITORY="${ECR_REPOSITORY:-uuid-service}"

# Optional safety check: ensure the commit is on origin/main if it exists.
if git -C "${ROOT_DIR}" rev-parse --verify origin/main >/dev/null 2>&1; then
  if ! git -C "${ROOT_DIR}" merge-base --is-ancestor "${COMMIT_SHA}" origin/main; then
    echo "Commit ${COMMIT_SHA} is not an ancestor of origin/main; refusing to deploy."
    exit 1
  fi
fi

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:${COMMIT_SHA}"

echo "Using image URI: ${IMAGE_URI}"

# Verify that CI has pushed this image to ECR.
if ! aws ecr describe-images \
  --repository-name "${ECR_REPOSITORY}" \
  --image-ids imageTag="${COMMIT_SHA}" >/dev/null 2>&1; then
  echo "Image ${IMAGE_URI} not found in ECR. Has CI built and pushed it yet?"
  exit 1
fi

export LAMBDA_IMAGE_URI="${IMAGE_URI}"

echo "Running infrastructure deploy via scripts/deploy.sh ..."
bash "${ROOT_DIR}/scripts/deploy.sh"

echo "Running post-deploy smoke test via scripts/smoke_test.sh ..."
bash "${ROOT_DIR}/scripts/smoke_test.sh"
