FROM public.ecr.aws/lambda/python:3.12

WORKDIR /var/task

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh -s -- --yes \
    && ln -s /root/.local/bin/uv /usr/local/bin/uv

COPY pyproject.toml ./
RUN uv sync --no-dev --system

COPY src/uuid_service/ ./uuid_service/

CMD ["uuid_service.handler.handler"]
