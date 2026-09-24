#!/bin/sh
set -e

cd /app

# APP_KEY por defecto si no se proveyó (solo para entornos de test)
if [ -z "$APP_KEY" ]; then
    export APP_KEY="base64:$(head -c 32 /dev/urandom | base64)"
fi

mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true

php artisan storage:link 2>/dev/null || true
php artisan migrate --force 2>&1 || echo "[entrypoint] migrate falló u omitido"
php artisan config:cache 2>&1 || true
php artisan route:cache 2>&1 || true
php artisan view:cache 2>&1 || true

exec frankenphp run --config /app/Caddyfile
