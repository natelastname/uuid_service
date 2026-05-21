#!/usr/bin/env bash

if [ -z "${LAMBDA_IMAGE_URI:-}" ]; then
  echo "Please set LAMBDA_IMAGE_URI to the ECR image URI."
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}/infra" || exit 1

if ! command -v tofu >/dev/null 2>&1; then
  echo "OpenTofu (tofu) is not installed or not on PATH."
  exit 1
fi

tofu init

tofu apply -auto-approve -var "lambda_image_uri=${LAMBDA_IMAGE_URI}"
