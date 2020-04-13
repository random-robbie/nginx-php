FROM justckr/ubuntu-nginx:latest

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update

RUN apt-get install -y software-properties-common \
    python-software-properties \
    language-pack-en-base

RUN LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y php7.3-fpm \
    php7.3-mysql \
    php7.3-curl \
    php7.3-gd \
    php7.3-intl \
    php7.3-mcrypt \
    php-memcache \
    php7.3-sqlite \
    php7.3-tidy \
    php7.3-xmlrpc \
    php7.3-pgsql \
    php7.3-ldap \
    freetds-common \
    php7.3-pgsql \
    php7.3-sqlite3 \
    php7.3-json \
    php7.3-xml \
    php7.3-mbstring \
    php7.3-soap \
    php7.3-zip \
    php7.3-cli \
    php7.3-sybase \
    php7.3-odbc \
    php7.3-dev


# Cleanup
RUN apt-get remove --purge -y software-properties-common \
    python-software-properties

RUN apt-get autoremove -y
RUN apt-get clean
RUN apt-get autoclean

#tweek php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.3/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.3/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.3/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.3/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.3/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.3/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.3/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.3/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.3/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.3/fpm/pool.d/www.conf
RUN sed -i -e "/listen\s*=\s*\/run\/php\/php7.3-fpm.sock/c\listen = 127.3.0.1:9100" /etc/php/7.3/fpm/pool.d/www.conf
RUN sed -i -e "/pid\s*=\s*\/run/c\pid = /run/php7.3-fpm.pid" /etc/php/7.3/fpm/php-fpm.conf

#fix ownership of sock file
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.3/fpm/pool.d/www.conf
RUN find /etc/php/7.3/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# Supervisor Config
ADD supervisord.conf /supervisord.conf
RUN cat /supervisord.conf >> /etc/supervisord.conf

# Start Supervisord
ADD start.sh /start.sh
RUN chmod 755 /start.sh

# Setup Volume
VOLUME ["/app"]

# add test PHP file
ADD index.php /app/src/public/index.php
ADD index.php /app/src/public/info.php
RUN chown -Rf www-data.www-data /app
RUN chown -Rf www-data.www-data /var/www/html


# Expose Ports
EXPOSE 443
EXPOSE 80

CMD ["/bin/bash", "/start.sh"]
