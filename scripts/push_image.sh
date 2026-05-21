#!/usr/bin/env bash

if [ -z "${AWS_ACCOUNT_ID:-}" ] || [ -z "${AWS_REGION:-}" ]; then
  echo "Please set AWS_ACCOUNT_ID and AWS_REGION environment variables."
  exit 1
fi

IMAGE_NAME="${IMAGE_NAME:-uuid-service}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REPOSITORY_NAME="${REPOSITORY_NAME:-uuid-service}"

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_URI="${ECR_REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG}"

aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${IMAGE_URI}"
docker push "${IMAGE_URI}"

echo "Pushed image to: ${IMAGE_URI}"
