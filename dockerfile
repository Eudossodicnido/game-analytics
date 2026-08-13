FROM python:3.12.13-slim-bookworm
WORKDIR /app

ENV POETRY_VIRTUALENVS_CREATE=false
ENV DAGSTER_HOME=/opt/dagster_home
RUN mkdir -p /opt/dagster_home


RUN pip install poetry==2.4.1 
COPY pyproject.toml poetry.lock ./
RUN poetry install --with pipeline --without dashboard --no-root


COPY dbt/ ./dbt/
COPY src/ ./src/


CMD ["dagster", "asset", "materialize", "--select", "bronze_games", "--module-name", "src.orchestration.definitions"]
