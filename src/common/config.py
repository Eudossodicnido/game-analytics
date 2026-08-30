from pathlib import Path
from dotenv import load_dotenv
import os
import datetime as dt


# Load environment variables from the .env file
load_dotenv()

# Variables

# Api
RAWG_API_KEY = os.getenv("RAWG_API_KEY")
API_URL = "https://api.rawg.io/api/games"
RANGE_METACRITIC_SCORE = "1,100"
API_PAGE_SIZE = 40
DELAY = 1.0
TIMEOUT = 30

# Backfill
BACKFILL_START_DATE = dt.date(2025, 1, 1)  # "1984-01-01"
BACKFILL_END_DATE = dt.date(2026, 7, 31)  # "2026-04-30"


# Environment
ENV = os.getenv("ENV")

# AWS
AWS_REGION = os.getenv("AWS_REGION")
S3_BUCKET_NAME = os.getenv("S3_BUCKET_NAME")


# Paths
PROJECT_ROOT = Path(__file__).resolve().parents[2]
# __file__ = .../game_analytics/src/common/config.py
# .parents[0] = src/common
# .parents[1] = src
# .parents[2] = game_analytics


FAILED_MONTHS_FILE_PATH = str(
    PROJECT_ROOT / "artifacts"
)  # since it's only used for backfill and we want to keep track of failed months, we can keep it local for simplicity. Alternatively, we could also store it in S3 if we want to access it from multiple environments.

if ENV == "local":
    RAW_STAGING_PATH = str(PROJECT_ROOT / "data" / "raw_staging")
    BRONZE_STAGING_PATH = str(PROJECT_ROOT / "data" / "bronze_staging")
    RAW_FILES_PATH = str(PROJECT_ROOT / "data" / "raw")
    BRONZE_FILES_PATH = str(PROJECT_ROOT / "data" / "bronze")
    SILVER_FILES_PATH = str(PROJECT_ROOT / "data" / "silver")
    GOLD_FILES_PATH = str(PROJECT_ROOT / "data" / "gold")
elif ENV == "prod":
    RAW_STAGING_PATH = f"s3://{S3_BUCKET_NAME}/raw_staging"
    BRONZE_STAGING_PATH = f"s3://{S3_BUCKET_NAME}/bronze_staging"
    RAW_FILES_PATH = f"s3://{S3_BUCKET_NAME}/raw"
    BRONZE_FILES_PATH = f"s3://{S3_BUCKET_NAME}/bronze"
    SILVER_FILES_PATH = f"s3://{S3_BUCKET_NAME}/silver"
    GOLD_FILES_PATH = f"s3://{S3_BUCKET_NAME}/gold"

else:
    raise ValueError("Invalid environment. Please set ENV to 'local' or 'prod'.")
