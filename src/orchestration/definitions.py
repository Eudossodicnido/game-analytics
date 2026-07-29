import dagster as dg
from src.orchestration.defs.dummy_asset import dummy_asset_example

defs = dg.Definitions(assets=[dummy_asset_example])
