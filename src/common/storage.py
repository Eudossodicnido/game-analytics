"""
This file contains utility functions for handling storage operations, such as deleting partitions and writing JSON files, for both local file systems and S3 buckets. The functions are designed to abstract away the differences between local and S3 storage, allowing the caller to use the same interface regardless of the underlying storage type.
"""

import boto3
import src.common.config  # noqa: F401  (runs load_dotenv as side effect)
from src.common.logging import setup_logging
import shutil
import json
import os

logger = setup_logging()


def _parse_s3_path(path: str) -> tuple[str, str]:
    """Splits an s3:// URL into (bucket, rest).
    Does not add or remove trailing slashes — caller decides."""
    without_scheme = path[len("s3://") :]
    bucket, rest = without_scheme.split("/", 1)
    return bucket, rest


def delete_partition(path: str) -> None:
    """
    This function deletes all objects in the given path, whether it's an S3 path or a local directory.
    """
    if path.startswith("s3://"):
        # parsing
        bucket, prefix = _parse_s3_path(path)
        # checking prefix ends with /
        if not prefix.endswith("/"):
            prefix += "/"

        # boto3 client
        client = boto3.client("s3")

        # list
        response = client.list_objects_v2(Bucket=bucket, Prefix=prefix)
        contents = response.get("Contents", [])
        if not contents:
            logger.info(f"Nothing to delete at {path}")

        # delete in bulk
        else:
            objects_to_delete = [{"Key": obj["Key"]} for obj in contents]
            client.delete_objects(Bucket=bucket, Delete={"Objects": objects_to_delete})
            logger.info(f"Deleted objects from {path}")
    else:
        # local
        try:
            shutil.rmtree(path)
            logger.info(f"Deleted local directory {path}")
        except FileNotFoundError:
            logger.info(f"Nothing to delete at {path}")


def write_json(path: str, data: dict) -> None:
    """
    This function writes a dictionary to a JSON file at the given path, whether it's an S3 path or a local file.
    """
    if path.startswith("s3://"):
        bucket, key = _parse_s3_path(path)
        payload = json.dumps(data, ensure_ascii=False, indent=2)
        client = boto3.client("s3")
        client.put_object(
            Bucket=bucket, Key=key, Body=payload, ContentType="application/json"
        )
        logger.info(f"Written to {path}")
    else:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        logger.info(f"Written to {path}")


if __name__ == "__main__":
    # test
    write_json("data/test-write/unicode.json", {"titolo": "Pokémon — Edizione Blu"})
