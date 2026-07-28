import logging


def setup_logging():
    logging.basicConfig(
        level=logging.INFO,  #  INFO level
        format="%(asctime)s - %(levelname)s - %(message)s",  # log format
    )
    logger = logging.getLogger(__name__)  # get name
    return logger
