# uuid_service

A tiny "peace-of-mind" UUID microservice, built as an interview‑friendly demo.

## Backstory

This project is inspired by a classic Hacker News comment:

> Ask HN: We just had an actual UUID v4 collision...
> “Funny story no one will believe, but it’s true. A good friend of mine joined a startup as CTO 10 years ago, high growth phase, maybe 200 devs… In his first week he discovered the company had a microservice for generating new UUIDs. One endpoint with its own dedicated team of 3 engineers …including a database guy (the plot thickens). Other teams were instructed to call this service every time they needed a new ‘safe’ UUID. My pal asked wtf. It turned out this service had its own DB to store every previously issued UUID. Requests were handled as follows: it would generate a UUID, then ‘validate’ it by checking its own database to ensure the newly generated UUID didn’t match any previously generated UUIDs, then insert it, then return it to the client. Peace of mind I guess. The team had its own kanban board and sprints.”

This repo is a small, realistic implementation of that idea.

## Technologies

- **Language / runtime**: Python 3.12
- **Serverless**: AWS Lambda (container image)
- **API**: AWS API Gateway HTTP API (root route, `GET /`)
- **Storage**: Amazon DynamoDB
- **Container**: Docker + AWS Lambda base image for Python 3.12
- **Registry**: Amazon ECR
- **IaC**: OpenTofu / Terraform (`infra/`, `platform/`)
- **Python tooling**: `pyproject.toml` + [`uv`](https://github.com/astral-sh/uv)
- **Task runner**: [`just`](https://github.com/casey/just)
- **CI/CD**: GitHub Actions (build/push Lambda image to ECR, deploy via OpenTofu)
- **Observability**: Amazon CloudWatch Logs for Lambda

## Features

- **UUID v4 microservice**: `GET /uuid` returns a freshly generated UUID v4 as JSON.
- **Persistence for "peace of mind"**: every issued UUID is written to DynamoDB with a conditional write to prevent duplicates.
- **Container‑based Lambda**: function is packaged and deployed as a Docker image, not a ZIP.
- **One‑command deploy from CI artifacts**: `scripts/deploy.sh` picks a commit’s image in ECR, runs OpenTofu, then executes a smoke test.
- **Cost tracking via tags**: AWS resources are consistently tagged (`Project`, `Environment`, etc.) for per‑app cost visibility.
- **Configurable project name**: tags and infra derive from a `project_name` variable instead of hardcoded strings.
- **Minimal but meaningful tests**: unit tests for UUID generation plus a Python smoke test hitting the real API Gateway endpoint.

## Architecture (at a glance)

- `src/uuid_service/handler.py` – AWS Lambda handler, wired to API Gateway HTTP API.
- `src/uuid_service/uuid_generator.py` – pure UUID v4 generation logic.
- `src/uuid_service/repository.py` – DynamoDB access and conditional writes.
- `infra/` – runtime infrastructure: Lambda, API Gateway, DynamoDB (OpenTofu / Terraform).
- `platform/` – platform/CI infrastructure: GitHub OIDC IAM role, Amazon ECR repository, etc.
- `scripts/build_image.sh` – build the Lambda container image.
- `scripts/push_image.sh` – push image to Amazon ECR.
- `scripts/deploy.sh` – deploy a specific commit’s image with OpenTofu and run the smoke test.
- `scripts/smoke_test.py` – calls the deployed API, asserts HTTP 200 and UUID v4.

## Local workflow (short version)

```bash
# Install Python dependencies (via uv and pyproject.toml)
uv sync

# Run tests
uv run pytest

# Build & push image (requires Docker + ECR repo)
just build
bash scripts/push_image.sh

# Deploy the current commit using the image from CI/ECR
bash scripts/deploy.sh
```

## Public demo

A live deployment of this service is available at:

- **UUID endpoint (custom domain)**: https://api.resultsmotivated.com/uuid_service

Example request:

```bash
curl https://api.resultsmotivated.com/uuid_service
# => {"uuid": "<uuid-v4>"}
```


