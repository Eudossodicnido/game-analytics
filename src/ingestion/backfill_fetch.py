"""
This script is responsible for backfilling historical data by fetching game data for each month within a specified date range. It keeps track of any months that fail to fetch and saves the list of failed months to a text file.
"""

from dateutil.relativedelta import relativedelta
import os
from src.common.config import (
    BACKFILL_START_DATE,
    BACKFILL_END_DATE,
    FAILED_MONTHS_FILE_PATH,
)
from src.common.logging import setup_logging
from src.ingestion.fetch import fetch_games

logger = setup_logging()


def run_backfill(start_date, end_date, output_path):
    """
    This function iterates through each month from start_date to end_date, attempts to fetch game data for that month, and logs the success or failure of each fetch. It also keeps track of any months that fail to fetch and saves the list of failed months to a text file at the specified output path.
    """
    list_of_failed_months = []  # to keep track of months that failed to fetch

    while start_date <= end_date:
        start_date_string = start_date.strftime(
            "%Y-%m"
        )  # because fetch_games expects a string in the format "YYYY-MM"
        logger.info(f"Starting to fetch data for {start_date_string}")
        try:
            fetch_games(start_date_string)
            logger.info(f"Successfully fetched data for {start_date_string}")
        except Exception as e:
            logger.error(f"Failed to fetch data for {start_date_string}: {e}")
            list_of_failed_months.append(start_date_string)
        start_date += relativedelta(months=+1)

    os.makedirs(output_path, exist_ok=True)
    with open(f"{output_path}/failed_fetched_months.txt", "w") as f:
        if not list_of_failed_months:
            f.write("All months fetched successfully!")
        else:
            for month in list_of_failed_months:
                f.write(f"{month}\n")


if __name__ == "__main__":
    run_backfill(BACKFILL_START_DATE, BACKFILL_END_DATE, FAILED_MONTHS_FILE_PATH)
