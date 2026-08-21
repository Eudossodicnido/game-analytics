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
                    CHAIN 'env;instance',
                    REGION '{AWS_REGION}'
                );
            """)
        logger.info(f"DuckDB connection opened (env={ENV})")
        yield conn
    finally:
        conn.close()
        logger.info(f"DuckDB connection closed (env={ENV})")


if __name__ == "__main__":
    with duckdb_connection() as conn:
        secrets = conn.execute("SELECT * FROM duckdb_secrets()").fetchall()
        if not secrets:
            logger.info("Test PASSED: no secrets in env=local")
        else:
            logger.error(f"Test FAILED: unexpected secrets in env=local: {secrets}")

    try:
        conn.execute("SELECT 1")
        logger.error("Test FAILED: connection was not closed")
    except Exception as e:
        logger.info(f"Test PASSED: connection closed correctly ({type(e).__name__})")
