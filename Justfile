# Justfile for uuid_service
# Mirrors the existing Makefile tasks using `just`.

# Default recipe: show available tasks
default:
    @just --list

# Build the Lambda container image using the helper script
build:
    bash scripts/build_image.sh

# Run unit tests (matches Makefile: PYTHONPATH=src pytest)
test:
    PYTHONPATH=src pytest

# Deploy infrastructure using OpenTofu via helper script
deploy:
    bash scripts/deploy.sh

# Deploy a specific commit from CI (wrapper around scripts/deploy_from_ci.sh)
deploy-from-ci:
    bash scripts/deploy_from_ci.sh

# Run the post-deploy smoke test against the live endpoint
smoke-test:
    bash scripts/smoke_test.sh
