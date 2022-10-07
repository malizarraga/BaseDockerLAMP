FROM ubuntu:latest

ENV TZ="America/Edmonton"
ENV DEBIAN_FRONTEND="noninteractive"
ENV PHP_VERSION="8.1"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get -y --allow-unauthenticated install \
  software-properties-common supervisor \
  openssl \
  wget vim git zip unzip curl dnsutils \
  unzip \
  ncurses-bin \
  net-tools \
  gcc make autoconf libc-dev pkg-config

RUN add-apt-repository ppa:ondrej/php

RUN apt-get update && apt-get -y --allow-unauthenticated install \
  php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-common php${PHP_VERSION}-curl php${PHP_VERSION}-dev php${PHP_VERSION}-gd php${PHP_VERSION}-intl \
  php${PHP_VERSION}-mbstring php${PHP_VERSION}-mysql php${PHP_VERSION}-opcache php${PHP_VERSION}-readline php${PHP_VERSION}-xml php${PHP_VERSION}-xmlrpc php${PHP_VERSION}-soap php${PHP_VERSION}-xdebug \
  php-apcu php-xdebug

# PHP CLI is getting PHP 8.1 Install some extensions to allow drush to work properly
RUN apt-get update && apt-get -y --allow-unauthenticated install \
  php${PHP_VERSION}-xml php${PHP_VERSION}-mysql php${PHP_VERSION}-soap php${PHP_VERSION}-mbstring php${PHP_VERSION}-gd

#--------------------------------------------------------------------#
# Install Tools
#--------------------------------------------------------------------#

# Install composer (set version to 1.x.x to prevent installing 2.0)
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
  php -r "unlink('composer-setup.php');"

# Install PHPUnit
RUN wget https://phar.phpunit.de/phpunit.phar && \
  chmod +x phpunit.phar && \
  mv phpunit.phar /usr/local/bin/phpunit

# Install Node:
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs

# Install NVM:
RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 

#--------------------------------------------------------------------#
# Configure
#--------------------------------------------------------------------#

# Configure PHP fpm.
COPY config/cli/php.ini /etc/php/${PHP_VERSION}/cli/php.ini
COPY config/fpm/php.ini /etc/php/${PHP_VERSION}/fpm/php.ini
COPY config/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Set up run directory for php fpm sock file.
RUN mkdir /var/run/php

# Set up the www-data user.
RUN chsh -s /bin/bash www-data
RUN mkdir /home/www-data
RUN usermod -d /home/www-data www-data

COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]