from src.common.config import RAW_FILES_PATH, BRONZE_FILES_PATH
from src.common.duckdb_client import duckdb_connection
from src.common.storage import delete_partition
from src.common.logging import setup_logging

logger = setup_logging()


def raw_to_bronze(year_month: str) -> None:

    pattern = f"{RAW_FILES_PATH}/date={year_month}/rawg_*.json"
    bronze_partition = f"{BRONZE_FILES_PATH}/date={year_month}"
    logger.info(f"Processing data for {year_month}")
    delete_partition(bronze_partition)
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
            TO '{BRONZE_FILES_PATH}' (FORMAT PARQUET, PARTITION_BY (date), OVERWRITE_OR_IGNORE)-->to avoid cancelling the rest of file and only rewrite actual month

            """,
            parameters=[pattern],
        )
        logger.info(f"Wrote data for {year_month}")


if __name__ == "__main__":
    # Example usage:
    raw_to_bronze("2017-10")
