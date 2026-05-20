#!/bin/bash
#
# Production entrypoint for the BAG wiki image.
#  - no command given        -> boot the app (wait for DB, migrate, serve)
#  - command given           -> run it directly (e.g. artisan one-offs)
set -e
cd /app

# Volumes can reset ownership of mounted paths — fix it on every boot.
mkdir -p storage/framework/sessions storage/framework/views \
         storage/framework/cache storage/logs storage/uploads public/uploads
chown -R www-data:www-data storage public/uploads bootstrap/cache

# One-off command mode: `docker compose run --rm app php artisan ...`
if [[ -n "$1" ]]; then
    exec "$@"
fi

# --- Full application boot ---

if [[ -z "$APP_KEY" || "$APP_KEY" == "SomeRandomString" ]]; then
    echo "FATAL: APP_KEY is not set."
    echo "Generate one with:"
    echo "  docker run --rm ghcr.io/baltimore-air-group/wiki:latest php artisan key:generate --show"
    exit 1
fi

if [[ -n "$DB_HOST" ]]; then
    echo "Waiting for database ${DB_HOST}:${DB_PORT:-3306} ..."
    wait-for-it "${DB_HOST}:${DB_PORT:-3306}" -t 60
fi

echo "Running database migrations ..."
php artisan migrate --force --no-interaction

echo "Starting Apache ..."
exec apache2-foreground
