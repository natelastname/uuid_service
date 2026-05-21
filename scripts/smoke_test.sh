#!/usr/bin/env bash

# Simple post-deploy smoke test:
# - Reads the API endpoint from OpenTofu outputs
# - Calls GET /uuid
# - Asserts HTTP 200 and that the body contains a valid UUIDv4

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="${ROOT_DIR}/infra"

if ! command -v tofu >/dev/null 2>&1; then
  echo "OpenTofu (tofu) is not installed or not on PATH."
  exit 1
fi

API_ENDPOINT="$(tofu -chdir="${INFRA_DIR}" output -raw api_endpoint)"

if [ -z "${API_ENDPOINT}" ]; then
  echo "api_endpoint output is empty; has the stack been deployed?"
  exit 1
fi

URL="${API_ENDPOINT%/}/uuid"

echo "Running smoke test against ${URL} ..."

response="$(curl -sS -w '\n%{http_code}' "${URL}")"
body="$(echo "${response}" | head -n1)"
status="$(echo "${response}" | tail -n1)"

if [ "${status}" != "200" ]; then
  echo "Smoke test failed: expected HTTP 200, got ${status}"
  echo "Body: ${body}"
  exit 1
fi

# Validate JSON and UUIDv4 using Python.
python - << 'PY'
import json
import sys
import uuid

body = sys.argv[1]

try:
    data = json.loads(body)
except json.JSONDecodeError as exc:
    raise SystemExit(f"Smoke test failed: response is not valid JSON: {exc}")

if "uuid" not in data:
    raise SystemExit("Smoke test failed: response JSON missing 'uuid' key")

try:
    value = str(data["uuid"])
    u = uuid.UUID(value)
except Exception as exc:
    raise SystemExit(f"Smoke test failed: invalid UUID: {exc}")

if u.version != 4:
    raise SystemExit(f"Smoke test failed: UUID version is {u.version}, expected 4")
PY "${body}"

echo "Smoke test passed."
