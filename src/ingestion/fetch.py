import requests
import datetime
import time
import calendar
from requests.exceptions import Timeout, ConnectionError, HTTPError
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception
from src.common.config import (
    RAWG_API_KEY,
    API_URL,
    RANGE_METACRITIC_SCORE,
    API_PAGE_SIZE,
    DELAY,
    TIMEOUT,
    STAGING_FILES_PATH,
    RAW_FILES_PATH,
)
from src.common.storage import delete_partition, write_json, move_staging_data
from src.common.logging import setup_logging

logger = setup_logging()


def should_retry(exception):
    """
    This function decides whether to retry a request based on the type of exception encountered.
    It checks for Timeout and ConnectionError exceptions, as well as HTTPError exceptions with status codes 429 (Too Many Requests) or any 5xx server error.
    If any of these conditions are met, it returns True to indicate that a retry should be attempted; otherwise, it returns False.
    """
    if isinstance(exception, (Timeout, ConnectionError)):
        logger.warning("Timeout error. Retrying...")
        return True
    elif (
        isinstance(exception, HTTPError)
        and (exception.response is not None)
        and (
            exception.response.status_code == 429
            or exception.response.status_code >= 500
        )
    ):
        logger.warning(
            f"Received status code {exception.response.status_code}. Retrying..."
        )
        return True
    else:
        return False


@retry(
    stop=stop_after_attempt(5),
    wait=wait_exponential(multiplier=1, min=1, max=10),
    retry=retry_if_exception(should_retry),
)
def _download_to_staging(staging_path: str, year_month: str) -> None:
    """
    This function deletes partition in the staging area and downloads and writes files in the staging area.
    Function is decorated with retry. Each attempt starts from a clean state to ensure idempotency.
    """
    delete_partition(staging_path)

    with requests.Session() as session:
        session.headers.update({"User-Agent": "rawg-dl/1.0"})

        # handling dates (from one to start and end to pass the API)
        year, month = year_month.split("-")
        year, month = int(year), int(month)
        start_date = f"{year_month}-01"
        last_day = calendar.monthrange(year, month)[1]
        end_date = f"{year_month}-{last_day}"

        url = API_URL
        params = {
            "key": RAWG_API_KEY,
            "dates": f"{start_date},{end_date}",
            "page_size": API_PAGE_SIZE,  # max from api docs
            "metacritic": RANGE_METACRITIC_SCORE,
            "ordering": "released",
        }

        page = 1
        while url is not None:
            logger.info(f"Fetching page {page}")
            resp = session.get(url, params=params, timeout=TIMEOUT)
            resp.raise_for_status()
            data = resp.json()

            results = data.get("results", [])
            if not results:
                logger.warning("No results available")
                break

            payload = {
                "downloaded_at": datetime.datetime.now(
                    datetime.timezone.utc
                ).isoformat(),
                "results": results,
            }
            file_path = f"{staging_path}rawg_page_{page}.json"
            write_json(file_path, payload)

            url = data.get("next")
            params = None
            page += 1
            time.sleep(DELAY)


def fetch_games(year_month: str) -> None:
    """
    This function calls _download_to_staging and only if the call is succesful, moves files from staging area to the raw area.
    """
    staging_path = f"{STAGING_FILES_PATH}/date={year_month}/"
    raw_path = f"{RAW_FILES_PATH}/date={year_month}/"
    _download_to_staging(staging_path=staging_path, year_month=year_month)
    delete_partition(raw_path)
    move_staging_data(source_path=staging_path, destination_path=raw_path)


if __name__ == "__main__":
    fetch_games(year_month="2017-10")
