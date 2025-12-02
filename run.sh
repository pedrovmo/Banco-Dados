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
  createdb)
    # cria o database se não existir (via container Docker)
    SQL_CHECK="SELECT 1 FROM pg_database WHERE datname='posto_combustivel';"
    if $COMPOSE ps -q db > /dev/null 2>&1; then
      EXISTS=$(docker-compose exec -T db psql -U postgres -d postgres -tAc "$SQL_CHECK" | tr -d '[:space:]' || true)
      if [ "$EXISTS" = "1" ]; then
        echo "Database 'posto_combustivel' já existe."
      else
        echo "Criando database 'posto_combustivel'..."
        docker-compose exec -T db psql -U postgres -d postgres -c "CREATE DATABASE posto_combustivel;"
      fi
    else
      echo "Container 'db' não está rodando. Execute './run.sh up' primeiro."
      exit 1
    fi
    ;;
  down)
    $COMPOSE down -v
    ;;
  apply)
    # Aplicar o script SQL via container Docker (requer serviço 'db' rodando)
    if $COMPOSE ps -q db > /dev/null 2>&1; then
      docker-compose exec -T db psql -U postgres -d posto_combustivel -f /docker-entrypoint-initdb.d/pratica-3.sql
    else
      echo "Container 'db' não está rodando. Execute './run.sh up' e tente novamente."
      exit 1
    fi
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
