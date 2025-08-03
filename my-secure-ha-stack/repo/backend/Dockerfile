# Dockerfile for Pure Bliss Backend (Laravel 11, PHP 8.3)

# Stage 1: Build
FROM composer:2.7 AS vendor
WORKDIR /app
COPY backend/ /app
RUN composer install --no-dev --optimize-autoloader

# Stage 2: Production
FROM php:8.3-fpm-alpine
LABEL maintainer="Pure Bliss DevOps <devops@purebliss.app>"

# Install system dependencies
RUN apk add --no-cache \
    bash \
    icu-dev \
    libzip-dev \
    oniguruma-dev \
    postgresql-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libxml2-dev \
    git \
    curl \
    supervisor

# PHP extensions
RUN docker-php-ext-install intl pdo pdo_pgsql zip opcache bcmath gd xml

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Set up user
RUN addgroup -g 101 purebliss && adduser -D -u 101 -G purebliss purebliss

WORKDIR /var/www/html

# Copy app source
COPY --chown=purebliss:purebliss backend/ /var/www/html
COPY --from=vendor /app/vendor /var/www/html/vendor

# Permissions
RUN chown -R purebliss:purebliss /var/www/html && chmod -R 755 /var/www/html

# Copy production configs
COPY backend/docker/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY backend/docker/supervisord.conf /etc/supervisord.conf

# Expose port
EXPOSE 9000

USER purebliss

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
