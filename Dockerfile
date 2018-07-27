#
# Dockerfile for Drupal 7 (Apache+PHP5.4 only)
#
# version: 0.1.0
#

FROM ubuntu:16.04
MAINTAINER Fernando Paredes Garcia <fernando@develcuy.com>

# Update packages
RUN apt-get update
RUN apt-get dist-upgrade -y

# Install package dependencies
RUN apt-get install -y supervisor vim make less git curl unzip mysql-client software-properties-common graphicsmagick

# Install Apache
RUN apt-get install -y apache2

# Configure Apache
RUN echo '[supervisord]\n\
nodaemon=true\n\
\n\
[program:apache2]\n\
command=/usr/bin/pidproxy /var/run/apache2/apache2.pid /bin/bash -c "source /etc/apache2/envvars && /usr/sbin/apache2 -DFOREGROUND"\n\
redirect_stderr=true\n'\
>> /etc/supervisor/conf.d/supervisord.conf
RUN mkdir /var/run/apache2 /var/lock/apache2 && chown www-data: /var/lock/apache2 /var/run/apache2
RUN echo '<VirtualHost *:80>\n\
\n\
        ServerAdmin webmaster@localhost\n\
\n\
        DocumentRoot /var/www\n\
        <Directory />\n\
                Options FollowSymLinks\n\
                AllowOverride None\n\
        </Directory>\n\
        <Directory /var/www/>\n\
                Options Indexes FollowSymLinks MultiViews\n\
                AllowOverride All\n\
                Order allow,deny\n\
                allow from all\n\
        </Directory>\n\
\n\
        ErrorLog ${APACHE_LOG_DIR}/error.log\n\
        CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
\n\
</VirtualHost>'\
> /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite vhost_alias
RUN service apache2 restart
VOLUME ["/var/www/"]
EXPOSE 80 443

## Install PHP5.6
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/apache2
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
RUN apt update
RUN apt-get install -y php5.6-cli php5.6-curl php5.6-json php5.6-mbstring \
  php5.6-mysql php5.6-opcache php5.6-readline php5.6-xml php5.6-xmlrpc \
  php5.6-zip libapache2-mod-php5.6

# Configure PHP5.6
RUN \
  sed -i "s/\(max_execution_time *= *\).*/\160/" /etc/php/5.6/apache2/php.ini;\
  sed -i "s/\(display_errors *= *\).*/\1On/" /etc/php/5.6/apache2/php.ini;\
  sed -i "s/\(display_startup_errors *= *\).*/\1Off/" /etc/php/5.6/apache2/php.ini;\
  sed -i "s/\(html_errors *= *\).*/\1On/" /etc/php/5.6/apache2/php.ini;\
  sed -i "s/\(post_max_size *= *\).*/\120M/" /etc/php/5.6/apache2/php.ini;\
  sed -i "s/\(upload_max_filesize *= *\).*/\120M/" /etc/php/5.6/apache2/php.ini;\
  sed -i "s/\(\;date.timezone *= *\).*/date.timezone\"America\\\Bogota\"/" /etc/php/5.6/apache2/php.ini;\
  sed -i "s/\(memory_limit *= *\).*/\1512M/" /etc/php/5.6/apache2/php.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; ln -s /usr/local/bin/composer /usr/bin/composer

# Install Drush
RUN mkdir /usr/local/src/composer; composer global require drush/drush -d /usr/local/src/composer/
RUN ln -s /usr/local/src/composer/vendor/drush/drush/drush /usr/local/bin/

WORKDIR /var/www

# Start supervisor
CMD ["/usr/bin/supervisord"]
