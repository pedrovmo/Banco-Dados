#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE="docker-compose"
DB_URL="postgresql://postgres:senha@localhost:5432/posto_combustivel"

usage() {
  cat <<EOF
Usage: $0 {up|down|apply|psql|status|logs}

Commands:
  up      Start the Postgres service (detached)
  down    Stop and remove containers and volumes
  apply   Apply the SQL script to the database
  psql    Open psql shell connecting to the database
  status  Show docker-compose services status
  logs    Tail DB logs
EOF
}

if [ ${#@} -eq 0 ]; then
  usage
  exit 1
fi

case "$1" in
  up)
    $COMPOSE up -d
    ;;
  down)
    $COMPOSE down -v
    ;;
  apply)
    # Try to run inside container first, fallback to local psql
    if $COMPOSE ps -q db > /dev/null 2>&1; then
      docker-compose exec -T db psql -U postgres -d posto_combustivel -f /docker-entrypoint-initdb.d/pratica-3.sql || true
    fi
    # fallback
    psql "$DB_URL" -f "$DIR/sql/pratica-3.sql" || true
    ;;
  psql)
    psql "$DB_URL"
    ;;
  status)
    $COMPOSE ps
    ;;
  logs)
    $COMPOSE logs -f db
    ;;
  *)
    usage
    exit 2
    ;;
esac
