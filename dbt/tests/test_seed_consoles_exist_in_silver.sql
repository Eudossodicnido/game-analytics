{# This test ensures that all console names in the mapping_console_platform_owner seed exist in the silver_games table. If there are any console names in the seed that do not exist in the silver_games table, this test will fail.
 #}

WITH silver_consoles_name AS (
SELECT
    DISTINCT unnested_consoles.unnest AS console_name
FROM 
    {{ ref('silver_games') }},
    UNNEST(console_names) AS unnested_consoles
)

SELECT
    seed.console_name

FROM
    {{ref('mapping_console_platform_owner')}} AS seed
LEFT JOIN
    silver_consoles_name AS silver
    ON seed.console_name = silver.console_name
WHERE
    silver.console_name IS NULL