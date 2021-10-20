FROM ubuntu:21.04

LABEL maintainer="Taylor Otwell"

ARG WWWGROUP

WORKDIR /var/www/html

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update
RUN apt-get install -y nginx


RUN apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python2 \
    && mkdir -p ~/.gnupg \
    && chmod 600 ~/.gnupg \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C300EE8C \
    && echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu hirsute main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update \
    && apt-get install -y php8.0-cli php8.0-dev \
       php8.0-pgsql php8.0-sqlite3 php8.0-gd \
       php8.0-curl php8.0-memcached \
       php8.0-imap php8.0-mysql php8.0-mbstring \
       php8.0-xml php8.0-zip php8.0-bcmath php8.0-soap \
       php8.0-intl php8.0-readline php8.0-pcov \
       php8.0-msgpack php8.0-igbinary php8.0-ldap \
       php8.0-redis php8.0-swoole php8.0-xdebug \
    && php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
    && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn \
    && apt-get install -y mysql-client \
    && apt-get install -y postgresql-client \
    && apt-get install -y vim \ 
    && apt-get install -y redis-tools \	
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN setcap "cap_net_bind_service=+ep" /usr/bin/php8.0
RUN groupadd sail
RUN useradd -ms /bin/bash --no-user-group -g www-data sail

# generate ssl key
RUN mkdir -p /etc/swoole/ssl/certs/ /etc/swoole/ssl/private/
RUN openssl req -x509 -nodes -days 365 -subj "/C=CA/ST=QC/O=Artisan, Inc./TW=localhost" \
    -addext "subjectAltName=DNS:localhost" -newkey rsa:2048 \
    -keyout /etc/swoole/ssl/private/sail-selfsigned.key \
    -out /etc/swoole/ssl/certs/sail-selfsigned.crt;
RUN chmod 644 /etc/swoole/ssl/certs/*.crt
RUN chown -R root:sail /etc/swoole/ssl/private/
RUN chmod 640 /etc/swoole/ssl/private/*.key
#

COPY start-container /usr/local/bin/start-container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /etc/php/8.0/cli/conf.d/99-sail.ini
COPY entrypoint.sh /etc/entrypoint.sh
COPY default /etc/nginx/sites-enabled/default
COPY index.html /var/www/html/public/index.html
COPY index.php /var/www/html/public/index.php

RUN chmod +x /etc/entrypoint.sh

EXPOSE 80 8000

ENTRYPOINT ["/etc/entrypoint.sh"]
