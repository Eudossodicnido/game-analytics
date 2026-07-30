import dagster as dg
from src.orchestration.defs.assets import silver_and_gold_games

defs = dg.Definitions(assets=[silver_and_gold_games])
