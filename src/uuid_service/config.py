import os
from dataclasses import dataclass
from typing import Optional


@dataclass
class AppConfig:
    table_name: str
    region_name: Optional[str]


def get_config() -> AppConfig:
    """Read configuration from environment variables.

    - UUID_TABLE_NAME: DynamoDB table name for storing UUIDs.
    - AWS_REGION: Optional explicit region override.
    """

    table_name = os.getenv("UUID_TABLE_NAME", "uuid_service_uuids")
    region_name = os.getenv("AWS_REGION")
    return AppConfig(table_name=table_name, region_name=region_name)
