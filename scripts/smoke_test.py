#!/usr/bin/env python3

"""Simple post-deploy smoke test.

- Reads the API endpoint from OpenTofu outputs
- Calls GET /
- Asserts HTTP 200 and that the body contains a valid UUIDv4
"""

import json
import subprocess
import sys
import uuid
from pathlib import Path


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    """Run a command, raising on non-zero exit."""
    return subprocess.run(cmd, check=True, text=True, capture_output=True, **kwargs)


def main() -> int:
    root_dir = Path(__file__).resolve().parent.parent
    infra_dir = root_dir / "infra"

    # Ensure OpenTofu is available.
    try:
        run(["tofu", "version"])
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("OpenTofu (tofu) is not installed or not on PATH.", file=sys.stderr)
        return 1

    # Read the API endpoint from OpenTofu outputs.
    try:
        result = run(["tofu", f"-chdir={infra_dir}", "output", "-raw", "api_endpoint"])
    except subprocess.CalledProcessError as exc:
        print(f"Failed to read api_endpoint output from OpenTofu: {exc.stderr}", file=sys.stderr)
        return 1

    api_endpoint = result.stdout.strip()
    if not api_endpoint:
        print("api_endpoint output is empty; has the stack been deployed?", file=sys.stderr)
        return 1

    # The API is now configured to serve the UUID at the root path.
    url = api_endpoint.rstrip("/")

    print(f"Running smoke test against {url} ...")

    # Call the endpoint using curl to avoid adding HTTP client deps.
    try:
        curl_result = subprocess.run(
            ["curl", "-sS", "-w", "\n%{http_code}", url],
            check=True,
            text=True,
            capture_output=True,
        )
    except FileNotFoundError:
        print("curl is not installed or not on PATH.", file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as exc:
        print(f"curl failed: {exc.stderr}", file=sys.stderr)
        return 1

    response = curl_result.stdout.splitlines()
    if not response:
        print("Smoke test failed: empty response from API.", file=sys.stderr)
        return 1

    body = response[0]
    status = response[-1]

    if status != "200":
        print(f"Smoke test failed: expected HTTP 200, got {status}", file=sys.stderr)
        print(f"Body: {body}", file=sys.stderr)
        return 1

    # Validate JSON and UUIDv4.
    try:
        data = json.loads(body)
    except json.JSONDecodeError as exc:
        print(f"Smoke test failed: response is not valid JSON: {exc}", file=sys.stderr)
        return 1

    if "uuid" not in data:
        print("Smoke test failed: response JSON missing 'uuid' key", file=sys.stderr)
        return 1

    try:
        value = str(data["uuid"])
        u = uuid.UUID(value)
    except Exception as exc:  # noqa: BLE001
        print(f"Smoke test failed: invalid UUID: {exc}", file=sys.stderr)
        return 1

    if u.version != 4:
        print(f"Smoke test failed: UUID version is {u.version}, expected 4", file=sys.stderr)
        return 1

    print("Smoke test passed.")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
