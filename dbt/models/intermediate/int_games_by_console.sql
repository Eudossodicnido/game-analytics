SELECT
    game_id,
    metacritic_score,
    unnested_consoles.unnest AS console_name,
    mapping.brand,
    mapping.is_handheld
FROM 
    {{ ref('silver_games') }},
    UNNEST(console_names) AS unnested_consoles
INNER JOIN
    {{ ref('mapping_console_platform_owner') }} AS mapping
    ON unnested_consoles.unnest = mapping.console_name
