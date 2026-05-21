import uuid

from uuid_service.uuid_generator import generate_uuid


def test_generate_uuid_returns_valid_uuid4() -> None:
    value = generate_uuid()
    parsed = uuid.UUID(value)
    assert parsed.version == 4
