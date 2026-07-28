SELECT 
  date,
  game.name AS game_name,
  game.released::DATE AS release_date,
  game.metacritic::INT AS metacritic_score,
  game.id::VARCHAR AS game_id,
  COALESCE(LIST_TRANSFORM(game.platforms, x -> x['platform']['name']::VARCHAR)) AS console_names, --to handle NULL values in platforms
  LIST_TRANSFORM(game.genres, x -> x['name']::VARCHAR) AS genre_names,
  --COALESCE(LIST_TRANSFORM(game.stores, x -> x['store']['name']::VARCHAR)) AS store_names,
  game.esrb_rating['name'] AS esrb_rating
FROM {{source('bronze','bronze_games')}}
