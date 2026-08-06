import dagster as dg
from src.orchestration.defs.assets import raw_rawg_api, bronze_games, silver_and_gold_games

defs = dg.Definitions(assets=[raw_rawg_api,bronze_games,silver_and_gold_games])
