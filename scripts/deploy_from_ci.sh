#!/usr/bin/env bash

# Deploy a specific commit from main using the image that CI built
# and pushed to ECR, then run a simple post-deploy smoke test.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Discover AWS account ID if not provided.
if [ -z "${AWS_ACCOUNT_ID:-}" ]; then
  if ! command -v aws >/dev/null 2>&1; then
    echo "AWS_ACCOUNT_ID is not set and aws CLI is not installed."
    exit 1
  fi
  AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)"
  if [ -z "${AWS_ACCOUNT_ID}" ]; then
    echo "Unable to determine AWS account ID via aws sts get-caller-identity."
    echo "Set AWS_ACCOUNT_ID explicitly and try again."
    exit 1
  fi
fi

# Discover AWS region if not provided.
if [ -z "${AWS_REGION:-}" ]; then
  if command -v aws >/dev/null 2>&1; then
    AWS_REGION="$(aws configure get region 2>/dev/null || true)"
  fi
  # Fallback to the infra default region if still empty.
  if [ -z "${AWS_REGION}" ]; then
    AWS_REGION="us-east-1"
  fi
fi

echo "Using AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}, AWS_REGION=${AWS_REGION}"

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

echo "Running post-deploy smoke test via scripts/smoke_test.py ..."
"${ROOT_DIR}/scripts/smoke_test.py"
