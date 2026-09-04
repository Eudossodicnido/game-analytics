from contextlib import contextmanager
import duckdb
import src.common.config  # noqa: F401 (side effect: load_dotenv)
from src.common.config import ENV, AWS_REGION
from src.common.logging import setup_logging

logger = setup_logging()


@contextmanager
def duckdb_connection():
    """
    This context manager creates a DuckDB connection, sets up the necessary extensions and secrets for S3 access if in production, and ensures that the connection is properly closed after use.
    """
    conn = duckdb.connect(database=":memory:")
    try:
        if ENV == "prod":
            conn.execute("INSTALL httpfs; LOAD httpfs;")
            conn.execute(f"""
                CREATE OR REPLACE SECRET s3_credentials (
                    TYPE s3,
                    PROVIDER credential_chain,
                    REGION '{AWS_REGION}'
                );
            """)
        logger.info(f"DuckDB connection opened (env={ENV})")
        yield conn
    finally:
        conn.close()
        logger.info(f"DuckDB connection closed (env={ENV})")
