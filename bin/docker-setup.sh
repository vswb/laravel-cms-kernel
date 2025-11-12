#! bin/bash
while getopts "e:" arg; do
  case $arg in
    e) ENV=$OPTARG;;
  esac
done

ENV="${ENV:-d}"
FILE_COMPOSE_DEVELOPMENT="docker-compose.yml"
FILE_COMPOSE_BETA="docker-compose.test.yml"
FILE_COMPOSE_PRODUCTION="docker-compose.production.yml"
FILE_ENV=".env"

case $ENV in
  d | dev) 
    docker compose -f $FILE_COMPOSE_DEVELOPMENT down && 
    docker compose --env-file $FILE_ENV -f $FILE_COMPOSE_DEVELOPMENT build --no-cache && 
    docker compose --env-file $FILE_ENV -f $FILE_COMPOSE_DEVELOPMENT up --force-recreate -d;;
  beta) 
    docker compose -f $FILE_COMPOSE_BETA down && 
    docker compose --env-file $FILE_ENV -f $FILE_COMPOSE_BETA build --no-cache && 
    docker compose --env-file $FILE_ENV -f $FILE_COMPOSE_BETA up --force-recreate -d;;
  p) 
    docker compose -f $FILE_COMPOSE_PRODUCTION down && 
    docker compose --env-file $FILE_ENV -f $FILE_COMPOSE_PRODUCTION build base --no-cache && 
    docker compose --env-file $FILE_ENV -f $FILE_COMPOSE_PRODUCTION build --no-cache && 
    docker compose --env-file $FILE_ENV -f $FILE_COMPOSE_PRODUCTION run --rm rails bundle exec rails db:chatwoot_prepare
    docker compose --env-file $FILE_ENV -f $FILE_COMPOSE_PRODUCTION run --rm rails bundle exec rspec
    docker compose --env-file $FILE_ENV -f $FILE_COMPOSE_PRODUCTION up --force-recreate -d;;
  rm)
    docker compose -f $FILE_COMPOSE_DEVELOPMENT down &&
    docker compose -f $FILE_COMPOSE_BETA down &&
    docker compose -f $FILE_COMPOSE_PRODUCTION down &&
    docker rmi -f $(docker images -aq);;
  *) 
    echo "ENV Unknown";;
esac

