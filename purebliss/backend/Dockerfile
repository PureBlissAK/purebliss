# Pure Bliss Backend (Laravel 11, PHP 8.3) - Production-Ready Dockerfile
FROM php:8.3-fpm-alpine as base


# Install system dependencies (including postgresql-dev for pdo_pgsql)
RUN apk add --no-cache bash git curl libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev icu-dev oniguruma-dev zlib-dev g++ make shadow supervisor postgresql-dev

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_pgsql pgsql zip intl mbstring exif pcntl bcmath opcache

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Create app user
RUN adduser -D -u 1001 appuser && mkdir -p /var/www && chown appuser:appuser /var/www

WORKDIR /var/www

# Copy application code (expecting volume mount in dev)
COPY . /var/www
RUN chown -R appuser:appuser /var/www


# Switch to non-root user
USER appuser

# Expose PHP-FPM port
EXPOSE 9000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD curl -f http://localhost:9000 || exit 1

CMD ["php-fpm"]
