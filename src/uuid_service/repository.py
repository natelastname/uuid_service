from dataclasses import dataclass

import boto3
from botocore.exceptions import ClientError

from .config import get_config
from .logging_utils import get_logger

logger = get_logger(__name__)


class UUIDStoreError(Exception):
    """Raised when the service cannot store a UUID in DynamoDB."""


@dataclass
class _RepositoryContext:
    table_name: str


_config = get_config()
_ctx = _RepositoryContext(table_name=_config.table_name)
_dynamodb = boto3.resource("dynamodb", region_name=_config.region_name)
_table = _dynamodb.Table(_ctx.table_name)


def store_uuid(uuid_value: str) -> None:
    """Store a UUID in DynamoDB, enforcing uniqueness via a conditional write."""
    try:
        _table.put_item(
            Item={"uuid": uuid_value},
            ConditionExpression="attribute_not_exists(#u)",
            ExpressionAttributeNames={"#u": "uuid"},
        )
    except ClientError as exc:
        logger.exception("Error storing UUID", extra={"uuid": uuid_value})
        raise UUIDStoreError(str(exc)) from exc
