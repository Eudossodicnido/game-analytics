{{ config(
  location=env_var('GOLD_FILES_PATH') ~ '/gold_agg_consoles.parquet'
  ) }}

SELECT 
    brand,
    console_name,
    is_handheld,
    ROUND(AVG(metacritic_score), 2) AS avg_metacritic_score,
    COUNT(DISTINCT game_id) AS number_of_games,
    COUNT(DISTINCT CASE WHEN metacritic_score >= {{ var('highly_rated_threshold') }} THEN game_id END) AS number_of_highly_rated_games,
    ROUND(
        COUNT(DISTINCT CASE WHEN metacritic_score >= {{ var('highly_rated_threshold') }} THEN game_id END) * 100.0
        / COUNT(DISTINCT game_id),
    2) AS percentage_of_highly_rated_games
 
FROM 
    {{ref('int_games_by_console')}}  AS games
GROUP BY 
    1, 2, 3