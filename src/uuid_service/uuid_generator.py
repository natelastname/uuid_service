import uuid


def generate_uuid() -> str:
    """Generate a new UUID4 as a string."""
    return str(uuid.uuid4())
