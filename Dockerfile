# Multi-stage build using uv for dependency resolution.
# Stage 1: uv tool image (build-time only)
FROM ghcr.io/astral-sh/uv:0.11.15 AS uv

# Stage 2: builder image based on the AWS Lambda Python runtime
FROM public.ecr.aws/lambda/python:3.12 AS builder

# Optional optimizations similar to the uv AWS Lambda guide
ENV UV_COMPILE_BYTECODE=1
ENV UV_NO_INSTALLER_METADATA=1
ENV UV_LINK_MODE=copy

WORKDIR /var/task

# Provide uv in the builder image
COPY --from=uv /uv /usr/local/bin/uv

# Install runtime dependencies into the Lambda task root.
# We don't use --frozen here yet since the project has no uv.lock.
COPY pyproject.toml ./
RUN uv export --no-emit-workspace --no-dev --no-editable -o requirements.txt \
    && uv pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Copy application code into the Lambda task root
COPY src/uuid_service/ "${LAMBDA_TASK_ROOT}/uuid_service"

# Stage 3: final runtime image
FROM public.ecr.aws/lambda/python:3.12

# Copy everything from the builder's Lambda task root into the final image
COPY --from=builder "${LAMBDA_TASK_ROOT}" "${LAMBDA_TASK_ROOT}"

CMD ["uuid_service.handler.handler"]
