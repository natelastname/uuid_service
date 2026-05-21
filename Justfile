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

# Deploy infrastructure using the image built by CI for this commit.
# This uses scripts/deploy_from_ci.sh, which discovers the AWS account,
# region, and image URI automatically when possible.
deploy:
    bash scripts/deploy_from_ci.sh

# Run the post-deploy smoke test against the live endpoint
smoke-test:
    scripts/smoke_test.py
