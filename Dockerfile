# syntax=docker/dockerfile:1

# ---------- assets (Vite / pnpm) ----------
FROM node:24-slim AS assets
RUN corepack enable
WORKDIR /app
COPY package.json pnpm-lock.yaml* pnpm-workspace.yaml .npmrc ./
RUN pnpm install --no-frozen-lockfile
COPY . .
RUN pnpm run build

# ---------- vendor (composer) ----------
FROM composer:2 AS vendor
WORKDIR /app
COPY . .
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

# ---------- runtime (FrankenPHP) ----------
FROM dunglas/frankenphp:php8.4 AS runtime
RUN install-php-extensions pdo_pgsql pgsql intl zip opcache
WORKDIR /app

COPY --from=vendor /app /app
COPY --from=assets /app/public/build /app/public/build
COPY docker/Caddyfile /app/Caddyfile
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
