import dagster as dg
import subprocess
import os
from src.common.config import BRONZE_FILES_PATH, SILVER_FILES_PATH, GOLD_FILES_PATH, ENV
from src.common.storage import delete_partition


@dg.asset
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
