# ===== Base: PHP extensions =====
FROM php:8.4-fpm AS base

RUN apt-get update && apt-get install -y \
    git curl zip unzip \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libonig-dev libxml2-dev libzip-dev libsqlite3-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_sqlite mbstring exif pcntl bcmath gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# ===== Node base: adds Node.js to base =====
FROM base AS node-base

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ===== Dev: все зависимости, без билда =====
FROM node-base AS dev

COPY composer.json composer.lock package.json package-lock.json ./
RUN composer install --prefer-dist
RUN npm install

COPY . .

RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]

# ===== Build: собираем фронт =====
FROM node-base AS build

COPY composer.json composer.lock package.json package-lock.json ./
RUN composer install --no-dev --no-scripts --prefer-dist
RUN npm ci

COPY . .

RUN composer dump-autoload --optimize
RUN npm run build

# ===== Production: минимальный образ без Node =====
FROM base AS production

COPY --from=build /var/www /var/www

RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
    && rm -rf /var/www/node_modules

USER www-data

EXPOSE 9000
CMD ["php-fpm"]
