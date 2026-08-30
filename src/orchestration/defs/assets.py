import dagster as dg
import subprocess
import os
from datetime import datetime, timezone
from dateutil.relativedelta import relativedelta
from src.ingestion.fetch import fetch_games
from src.ingestion.raw_to_bronze import raw_to_bronze
from src.common.config import BRONZE_FILES_PATH, SILVER_FILES_PATH, GOLD_FILES_PATH, ENV
from src.common.storage import delete_partition


def _months_for_assets() -> list[str]:
    year_month = os.environ.get("YEAR_MONTH")
    lag_months = int(os.environ.get("LAG_MONTHS", 24))
    window_months = int(os.environ.get("WINDOW_MONTHS", 3))
    if year_month:
        return [year_month]
    else:
        last_month_two_years_ago = datetime.now(timezone.utc) + relativedelta(
            months=-lag_months
        )
        months_list = [last_month_two_years_ago.strftime("%Y-%m")]
        for _ in range(window_months - 1):
            month_plus_one = last_month_two_years_ago + relativedelta(months=+1)
            months_list.append(month_plus_one.strftime("%Y-%m"))
            last_month_two_years_ago = month_plus_one
        return months_list


@dg.asset
def raw_rawg_api(context: dg.AssetExecutionContext) -> None:
    months_list = _months_for_assets()
    context.log.info(f"List of months to process: {months_list}")
    for year_month in months_list:
        context.log.info(f"Starting {year_month}")
        fetch_games(year_month)
        context.log.info(f"Finished {year_month}")


@dg.asset(deps=[raw_rawg_api])
def bronze_games(context: dg.AssetExecutionContext) -> None:
    months_list = _months_for_assets()
    context.log.info(f"List of months to process: {months_list}")
    for year_month in months_list:
        context.log.info(f"Starting {year_month}")
        raw_to_bronze(year_month)
        context.log.info(f"Finished {year_month}")


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
