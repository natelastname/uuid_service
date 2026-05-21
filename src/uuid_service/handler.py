import json
from typing import Any, Dict

from .logging_utils import get_logger
from .uuid_generator import generate_uuid
from .repository import UUIDStoreError, store_uuid

logger = get_logger(__name__)


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """AWS Lambda handler for API Gateway HTTP API events.

    Generates a UUID, stores it in DynamoDB, and returns it as JSON.
    """
    logger.info("Received event", extra={"event": event})

    uuid_value = generate_uuid()

    try:
        store_uuid(uuid_value)
    except UUIDStoreError:
        logger.exception("Failed to store UUID", extra={"uuid": uuid_value})
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": "Failed to store UUID"}),
        }

    response_body = {"uuid": uuid_value}
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(response_body),
    }
