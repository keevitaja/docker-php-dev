FROM php:8.0-apache

ARG DOCKER_APP_NAME
ARG DOCKER_APP_UID
ARG DOCKER_APP_GID
ARG DOCKER_APP_USERNAME
ARG DOCKER_APP_HOSTNAME
ARG DOCKER_APP_DOCROOT

RUN apt-get update && apt-get install -y \
    libzip-dev \
    libmemcached-dev \
    zlib1g-dev \
    openssl \
    git \
    supervisor \
    unzip \
    openssh-server \
    libicu-dev \
    libpng-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libxml2-dev \
    libxslt-dev

RUN docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install \
    zip \
    pdo_mysql \
    pcntl \
    opcache \
    intl \
    soap \
    xsl \
    sockets \
    -j$(nproc) gd

RUN pecl install \
    memcached-3.1.5 \
    redis

RUN docker-php-ext-enable \
    memcached \
    redis

RUN groupadd -g ${DOCKER_APP_GID} -f ${DOCKER_APP_USERNAME}
RUN useradd -s /bin/bash ${DOCKER_APP_USERNAME} -u ${DOCKER_APP_UID} -g ${DOCKER_APP_GID} -d /home/user
RUN chown -R ${DOCKER_APP_USERNAME}:${DOCKER_APP_USERNAME} /var/www/html

COPY vhost.conf /etc/apache2/sites-available/vhost.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /usr/local/etc/php/conf.d

RUN sed -i "s/docker_app_hostname/${DOCKER_APP_HOSTNAME}/g" /etc/apache2/sites-available/vhost.conf
RUN sed -i "s/docker_app_docroot/${DOCKER_APP_DOCROOT}/g" /etc/apache2/sites-available/vhost.conf
RUN sed -i "s/docker_app_username/${DOCKER_APP_USERNAME}/g" /etc/supervisor/conf.d/supervisord.conf

RUN ln -s /etc/apache2/sites-available/vhost.conf /etc/apache2/sites-enabled/vhost.conf

RUN mkdir -p /var/log/supervisor
RUN mkdir -p /run/sshd
RUN mkdir -p /var/log/app

RUN php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer

RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod ssl

RUN openssl req -x509 -nodes -days 365 \
    -subj "/C=CA/ST=QC/O=Company, Inc./CN=${DOCKER_APP_HOSTNAME}" \
    -addext "subjectAltName=DNS:${DOCKER_APP_HOSTNAME}" \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/selfsigned.key \
    -out /etc/ssl/certs/selfsigned.crt

EXPOSE 22 80 443

CMD ["/usr/bin/supervisord"]
