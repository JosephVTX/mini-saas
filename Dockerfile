# syntax=docker/dockerfile:1

# ---------- builder (PHP + Node + Composer) ----------
# Un solo stage porque Wayfinder (plugin de Vite) invoca `php artisan wayfinder:generate`.
FROM dunglas/frankenphp:php8.4 AS builder
RUN install-php-extensions pdo_pgsql pgsql intl zip opcache
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl gnupg ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /app

# APP_KEY dummy solo para poder bootear artisan en build (el real llega por entorno en runtime)
ENV APP_ENV=production \
    APP_KEY=base64:dX1stLm+VMoNR7J5NAuuxRR0TcGOdkP7LpE/H5XekZg=

COPY . .
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader \
    && pnpm install --no-frozen-lockfile \
    && pnpm run build \
    && rm -rf /app/node_modules

# ---------- runtime (FrankenPHP) ----------
FROM dunglas/frankenphp:php8.4 AS runtime
RUN install-php-extensions pdo_pgsql pgsql intl zip opcache
WORKDIR /app

COPY --from=builder /app /app
COPY docker/Caddyfile /app/Caddyfile
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
