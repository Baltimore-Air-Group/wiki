# syntax=docker/dockerfile:1
#
# Production image for the BAG wiki: BookStack + the themes/bag/ theme,
# baked in. Published to GHCR by .github/workflows/publish-image.yml.
#
# Local build:  docker build -t ghcr.io/baltimore-air-group/wiki:latest .

# ---- Stage 1: build front-end assets (CSS + JS bundles) ------------
FROM node:22-alpine AS assets
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run production

# ---- Stage 2: production runtime -----------------------------------
FROM php:8.3-apache AS app

# OS libraries + PHP extensions BookStack needs (mirrors
# dev/docker/Dockerfile, minus Xdebug, plus opcache for production).
RUN apt-get update && apt-get install -y --no-install-recommends \
        git zip unzip wait-for-it \
        libfreetype-dev libjpeg62-turbo-dev libldap2-dev libpng-dev libzip-dev \
    && docker-php-ext-configure ldap --with-libdir="lib/$(gcc -dumpmachine)" \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" pdo_mysql gd ldap zip opcache \
    && rm -rf /var/lib/apt/lists/*

# Production PHP config (larger limits for documentation uploads).
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && sed -i 's/memory_limit = 128M/memory_limit = 512M/' "$PHP_INI_DIR/php.ini" \
    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/' "$PHP_INI_DIR/php.ini" \
    && sed -i 's/post_max_size = 8M/post_max_size = 50M/' "$PHP_INI_DIR/php.ini" \
    && { \
        echo 'opcache.enable=1'; \
        echo 'opcache.validate_timestamps=0'; \
        echo 'opcache.max_accelerated_files=20000'; \
        echo 'opcache.memory_consumption=192'; \
    } > "$PHP_INI_DIR/conf.d/opcache.ini"

# Apache: document root -> public/, enable rewrite + .htaccess.
ENV APACHE_DOCUMENT_ROOT="/app/public"
RUN a2enmod rewrite headers \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && sed -ri -e 's!AllowOverride None!AllowOverride All!g' /etc/apache2/apache2.conf

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
RUN git config --system --add safe.directory /app

# App source (incl. themes/bag/) + freshly built assets, then PHP deps.
COPY . .
COPY --from=assets /app/public/dist ./public/dist
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist \
    && mkdir -p storage public/uploads bootstrap/cache \
    && chown -R www-data:www-data storage public/uploads bootstrap/cache

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
