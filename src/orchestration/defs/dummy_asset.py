import dagster as dg


@dg.asset
def dummy_asset_example(context: dg.AssetExecutionContext) -> None:
    context.log.info(f"My run ID is {context.run_id}")
