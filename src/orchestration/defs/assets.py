import dagster as dg
import subprocess
import os
from datetime import datetime, timezone
from dateutil.relativedelta import relativedelta
from src.ingestion.fetch import fetch_games
from src.ingestion.raw_to_bronze import raw_to_bronze
from src.common.config import BRONZE_FILES_PATH, SILVER_FILES_PATH, GOLD_FILES_PATH, ENV
from src.common.storage import delete_partition


@dg.asset
def raw_rawg_api(context: dg.AssetExecutionContext) -> None:
    year_month = os.environ.get(
        "YEAR_MONTH",
        (datetime.now(timezone.utc) + relativedelta(months=-1)).strftime("%Y-%m"),
    )
    context.log.info(f"Starting {year_month}")
    fetch_games(year_month)
    context.log.info(f"Wrote data for {year_month}")


@dg.asset(deps=[raw_rawg_api])
def bronze_games(context: dg.AssetExecutionContext) -> None:
    year_month = os.environ.get(
        "YEAR_MONTH",
        (datetime.now(timezone.utc) + relativedelta(months=-1)).strftime("%Y-%m"),
    )
    context.log.info(f"Starting {year_month}")
    raw_to_bronze(year_month)
    context.log.info(f"Wrote data for {year_month}")


@dg.asset(deps=[bronze_games])
def silver_and_gold_games(context: dg.AssetExecutionContext) -> None:

    context.log.info(f"cwd is: {os.getcwd()}")
    context.log.info(f"BRONZE_FILES_PATH is: {BRONZE_FILES_PATH}")
    context.log.info(f"SILVER_FILES_PATH is: {SILVER_FILES_PATH}")
    context.log.info(f"GOLD_FILES_PATH is: {GOLD_FILES_PATH}")
    context.log.info(f"ENV is: {ENV}")

    # Set environment variables for file paths to be used in dbt models
    os.environ["BRONZE_FILES_PATH"] = BRONZE_FILES_PATH
    os.environ["SILVER_FILES_PATH"] = SILVER_FILES_PATH
    os.environ["GOLD_FILES_PATH"] = GOLD_FILES_PATH

    delete_partition(SILVER_FILES_PATH)
    delete_partition(GOLD_FILES_PATH)
    if ENV == "local":
        os.makedirs(GOLD_FILES_PATH, exist_ok=True)

    subprocess.run(["dbt", "build", "--target", ENV], cwd="dbt", check=True)
