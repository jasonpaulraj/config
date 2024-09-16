FROM php:8.0.2-apache
ARG env

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash

# 1. development packages
RUN apt-get update && apt-get install -y libicu-dev \
        libpq-dev \
        libbz2-dev \
        zlib1g-dev \
        libfreetype6-dev \
        libwebp-dev  \
        libjpeg62-turbo-dev \
        libpng-dev \
        libzip-dev \
        libonig-dev \
        supervisor \
        git \
        unzip \
        zip \
        nodejs \
        rsync \
        cron \
        exif \
        imagemagick \
        libmagickwand-dev \
        libmagickcore-dev \
        vim \
        sudo \ 
        openssl \
        libssl-dev \ 
        wkhtmltopdf \
        postfix

# 2. apache configs + document root
ENV APACHE_DOCUMENT_ROOT=/var/www/mov-mm-backend/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 3. mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers

# 4. start with base php config, then add extensions
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN docker-php-ext-configure intl
RUN docker-php-ext-install mysqli \ 
        intl \
        opcache \
        zip \
        sockets \
        # install mysql driver for php
        pdo \
        pdo_mysql \
        exif \
        bz2 \
        intl \
        iconv \
        bcmath \
        calendar \
        mbstring

RUN docker-php-ext-install gd

# install imagick
# use github version for now until release from https://pecl.php.net/get/imagick is ready for PHP 8
RUN git clone https://github.com/Imagick/imagick \ 
 && cd imagick \ 
 && ls \ 
 && phpize && ./configure \ 
 && make \
 && make install \ 
 && cd ../ \ 
 && rm -rf imagick \ 
 && docker-php-ext-enable imagick

# 5. composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 6. we need a user with the same UID/GID with host user
# so when we execute CLI commands, all the host file's ownership remains intact
# otherwise command from inside container will create root-owned files and directories
ARG uid
RUN useradd -G www-data,root -u 1000 -d /home/devuser devuser
RUN mkdir -p /home/devuser/.composer && \
    chown -R devuser:devuser /home/devuser


# Setup cron
#COPY docker/cron/laravel-scheduler-cron /etc/cron.d/laravel-scheduler-cron
#RUN chmod 0744 /etc/cron.d/laravel-scheduler-cron
#RUN crontab /etc/cron.d/laravel-scheduler-cron
# CMD cron

ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="10000" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="192" \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE="10"

COPY docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/php/conf.d/upload-limit.ini /usr/local/etc/php/conf.d/upload-limit.ini

RUN echo 'memory_limit = -1' >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini
# apache setup
# COPY vhost.conf /etc/apache2/sites-available/000-default.conf
# EXPOSE 80

WORKDIR /tmp
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
#RUN composer global require hirak/prestissimo
COPY composer.json composer.lock package.json package-lock.json ./
RUN if [ "$env" = "development" ] ; then composer install --no-scripts ; else composer install --no-scripts --no-dev ; fi
RUN npm install

WORKDIR /var/www/mov-mm-backend
COPY . ./
RUN rsync -ah /tmp/* ./
RUN npm run dev
RUN chmod -Rf 777 /var/www/mov-mm-backend/storage
RUN chown www-data:www-data /var/www/mov-mm-backend && a2enmod rewrite
#RUN cp /var/www/mov-mm-backend/supervisor/* /etc/supervisor/conf.d/
RUN composer dump-autoload
