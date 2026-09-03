from duckdb import IOException

from src.common.config import RAW_FILES_PATH, BRONZE_STAGING_PATH, BRONZE_FILES_PATH
from src.common.duckdb_client import duckdb_connection
from src.common.storage import delete_partition, move_staging_data
from src.common.logging import setup_logging

logger = setup_logging()


def _write_to_staging(staging_path: str, year_month: str) -> bool:
    """
    This function gets json files from raw folder, partition by date, builds a parquet file via duckdb
    and puts in a staging area.
    If there is no data to transform, it handles the exception.
    """
    delete_partition(f"{staging_path}/date={year_month}")
    wrote = False
    pattern = f"{RAW_FILES_PATH}/date={year_month}/rawg_*.json"
    logger.info(f"Processing data for {year_month}")
    try:
        with duckdb_connection() as conn:
            conn.execute(
                f"""
            COPY (
                SELECT 
                    downloaded_at,
                    date, --date is not in the original json but we can extract it from the partitioning
                    UNNEST(results) AS game
                FROM
                    read_json(?) 
                )
                TO '{BRONZE_STAGING_PATH}' (FORMAT PARQUET, PARTITION_BY (date), OVERWRITE_OR_IGNORE) -->to avoid cancelling the rest of file and only rewrite actual month (should not happen anymore with implementation of staging area)

                """,
                parameters=[pattern],
            )
            logger.info(f"Wrote data for {year_month}")
            wrote = True
    except IOException as e:
        if "No files found that match the pattern" in str(e):
            wrote = False
        else:
            raise
    return wrote


def raw_to_bronze(year_month: str) -> None:
    """
    This function calls _write_to_staging.
    If operation is succesful, data is moved to bronze folder and staging partition is deleted.
    """
    bronze_staging_partition = f"{BRONZE_STAGING_PATH}/date={year_month}"
    bronze_partition = f"{BRONZE_FILES_PATH}/date={year_month}"
    wrote_to_staging = _write_to_staging(BRONZE_STAGING_PATH, year_month)
    if wrote_to_staging:
        delete_partition(bronze_partition)
        move_staging_data(
            source_path=bronze_staging_partition, destination_path=bronze_partition
        )
    else:
        logger.info(f"No data to transform for {year_month}")


if __name__ == "__main__":
    # Example usage:
    raw_to_bronze("2017-10")
