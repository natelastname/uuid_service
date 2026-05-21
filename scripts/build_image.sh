#!/usr/bin/env bash

IMAGE_NAME="${IMAGE_NAME:-uuid-service}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
