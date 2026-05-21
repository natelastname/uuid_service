# uuid_service

This project is inspired by a HackerNews comment:

> Ask HN: We just had an actual UUID v4 collision...
> “Funny story no one will believe, but it’s true. A good friend of mine joined a startup as CTO 10 years ago, high growth phase, maybe 200 devs… In his first week he discovered the company had a microservice for generating new UUIDs. One endpoint with its own dedicated team of 3 engineers …including a database guy (the plot thickens). Other teams were instructed to call this service every time they needed a new ‘safe’ UUID. My pal asked wtf. It turned out this service had its own DB to store every previously issued UUID. Requests were handled as follows: it would generate a UUID, then ‘validate’ it by checking its own database to ensure the newly generated UUID didn’t match any previously generated UUIDs, then insert it, then return it to the client. Peace of mind I guess. The team had its own kanban board and sprints.” 

The purpose of this project is to implement this service as a small, self-contained microservice that generates UUID v4 values and persists every issued value for "peace of mind".

## High-level architecture

- **Runtime**: AWS Lambda, deployed as a **container image** based on a recent Amazon Linux–backed Python runtime (Lambda base image for Python 3.12).
- **Interface**: AWS API Gateway (HTTP API) exposing a `GET /uuid` endpoint.
- **Storage**: DynamoDB table that stores every issued UUID as a single primary-key item, enforcing uniqueness via conditional writes.
- **Infrastructure-as-code**: OpenTofu (Terraform-compatible) configuration under `infra/`.
- **Verification**: Post-deploy smoke tests (planned) that call the live API and assert it returns a valid UUID and stores it.

## Design decisions

### Lambda as a container image

Instead of deploying a ZIP, the function is packaged as a **Docker image** using the official AWS Lambda base image for Python 3.12:

- Gives full control over the runtime environment while staying compatible with Lambda's execution model.
- Makes it easy to add native or larger dependencies later without fighting ZIP size limits.
- Image is built locally and pushed to **Amazon ECR**, and Lambda is configured to use the resulting `image_uri`.

Key files:

- `Dockerfile` – builds the Lambda container image.
- `.dockerignore` – keeps build contexts small and images lean.

### Service behavior

The Lambda handler is a small HTTP-style function that:

1. Receives an API Gateway HTTP API event.
2. Generates a new UUID v4.
3. Attempts to store it in DynamoDB using a **conditional write** (`attribute_not_exists(uuid)`) so collisions fail fast.
4. Returns either:
   - `200 OK` with JSON body `{ "uuid": "..." }` on success, or
   - `500` with a simple JSON error if persistence fails.

This mirrors the original anecdote: every UUID is validated against all previously issued ones by virtue of DynamoDB's uniqueness on the primary key.

### AWS resources

Provisioned resources (via OpenTofu):

- **DynamoDB table** (in `infra/modules/dynamodb_uuids`):
  - On-demand (`PAY_PER_REQUEST`) billing.
  - Partition key: `uuid` (string).
- **Lambda function** (in `infra/modules/lambda_uuid_service`):
  - `package_type = "Image"`, pointing at an ECR image URI.
  - IAM role with:
    - Basic CloudWatch Logs permissions.
    - `dynamodb:PutItem` permissions on the UUID table.
  - Environment variable `UUID_TABLE_NAME` to point at the table.
- **API Gateway HTTP API** (in `infra/modules/api_gateway`):
  - Route: `GET /uuid` → Lambda proxy integration.
  - Stage with auto-deploy enabled.
  - Lambda permission allowing invocation from the API.

## Repository layout

At a high level, the repository is organized like this:

```text
uuid_service/
  Dockerfile          # Lambda container image definition
  .dockerignore
  requirements.txt    # Python dependencies (boto3, etc.)
  Makefile            # build, test, deploy shortcuts

  src/uuid_service/
    __init__.py
    handler.py        # Lambda handler (uuid_service.handler.handler)
    uuid_generator.py # pure UUID v4 generation logic
    repository.py     # DynamoDB persistence and uniqueness enforcement
    config.py         # environment/config handling
    logging_utils.py  # simple structured logging helper

  tests/
    unit/
      test_uuid_generator.py    # basic unit test for UUID generation

  infra/
    main.tf         # wires modules together
    variables.tf
    outputs.tf
    modules/
      dynamodb_uuids/
        main.tf      # DynamoDB table definition
      lambda_uuid_service/
        main.tf      # Lambda + IAM + env vars
      api_gateway/
        main.tf      # HTTP API, route, stage, permissions

  scripts/
    build_image.sh   # docker build
    push_image.sh    # docker push to ECR
    deploy.sh        # OpenTofu apply using an image URI
```

## Local development

### Prerequisites

- Docker
- Python 3.12 (for local tests)
- [`uv`](https://github.com/astral-sh/uv) for Python dependency management
- OpenTofu (`tofu`) for IaC (Terraform-compatible CLI)
- AWS CLI configured with credentials and a default region

### Install dependencies

```bash
uv sync
```

### Run tests

```bash
uv run pytest tests/unit
```
## Building and deploying

### Build the Lambda container image

```bash
just build
# or
IMAGE_NAME=uuid-service IMAGE_TAG=v0.1.0 just build
```

### Push to ECR

You need an existing ECR repository (e.g., `uuid-service`). Then:

```bash
export AWS_ACCOUNT_ID=123456789012
export AWS_REGION=us-east-1
export IMAGE_TAG=v0.1.0
export REPOSITORY_NAME=uuid-service

bash scripts/push_image.sh
```

The script prints the full image URI, e.g.:

```text
123456789012.dkr.ecr.us-east-1.amazonaws.com/uuid-service:v0.1.0
```

### Deploy a specific commit from CI

CI builds and pushes a container image for every commit on `main`, tagged
with the commit SHA. You can deploy one of those images from your laptop
and run a smoke test:

```bash
export AWS_ACCOUNT_ID=123456789012
export AWS_REGION=us-east-1

# Optional: override which commit to deploy (defaults to HEAD)
# export COMMIT_SHA=abcd1234...

bash scripts/deploy_from_ci.sh
```

This script:

- Derives the ECR image URI as:
  `"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/uuid-service:${COMMIT_SHA}"`
- Verifies the image exists in ECR (i.e., CI has built and pushed it).
- Runs `scripts/deploy.sh` (OpenTofu `apply` with `lambda_image_uri` set).
- Runs `scripts/smoke_test.sh`, which:
  - Reads `api_endpoint` from `tofu output`.
  - Calls `GET /uuid`.
  - Asserts HTTP 200 and that the JSON body contains a valid UUID v4.

If any step fails, the script exits with a non-zero status.


### Deploy with OpenTofu

Use the ECR image URI from the previous step:

```bash
export LAMBDA_IMAGE_URI=123456789012.dkr.ecr.us-east-1.amazonaws.com/uuid-service:v0.1.0

just deploy
```

After a successful `tofu apply`, the `infra` outputs will include an `api_endpoint` value. You can then call:

```bash
curl "$(tofu -chdir=infra output -raw api_endpoint)/uuid"
```

to receive a newly generated UUID that has been stored in DynamoDB.




