{{ config(
  location=env_var('GOLD_FILES_PATH') ~ '/gold_agg_brands.parquet'
  ) }}
WITH deduped_games AS ( {# Remove duplicates to avoid skewing the average and counts #}
    SELECT 
        DISTINCT game_id,
        metacritic_score,
        brand
    FROM 
        {{ref('int_games_by_console')}}
)

SELECT 
    brand,
    ROUND(AVG(metacritic_score), 2) AS avg_metacritic_score,
    COUNT( game_id) AS number_of_games,
    COUNT( CASE WHEN metacritic_score >= {{ var('highly_rated_threshold') }} THEN game_id END) AS number_of_highly_rated_games,
    ROUND(
        COUNT( CASE WHEN metacritic_score >= {{ var('highly_rated_threshold') }} THEN game_id END) * 100.0
        / COUNT( game_id),
    2) AS percentage_of_highly_rated_games

FROM 
    deduped_games AS games
GROUP BY 
    1