#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export COMPOSER_ALLOW_SUPERUSER=1
export ZEPHIRDIR=/usr/share/zephir
export LANGUAGE=en_GB.UTF-8
export LANG=en_GB.UTF-8
export LC_ALL=en_GB.UTF-8

#
# Add Swap
#
sudo dd if=/dev/zero of=/swapspace bs=1M count=4000
sudo mkswap /swapspace
sudo swapon /swapspace
echo "/swapspace none swap defaults 0 0" >> /etc/fstab

echo nameserver 8.8.8.8 > /etc/resolv.conf
echo nameserver 8.8.4.4 > /etc/resolv.conf

#
# Add PHP and PostgreSQL repositories
#
LC_ALL=en_GB.UTF-8 add-apt-repository -y ppa:ondrej/php
apt-add-repository -y ppa:chris-lea/libsodium
add-apt-repository -y ppa:chris-lea/redis-server
touch /etc/apt/sources.list.d/pgdg.list
echo -e "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" | tee -a /etc/apt/sources.list.d/pgdg.list &>/dev/null
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Cleanup package manager
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

apt-key update
apt-get update -qq
apt-get upgrade -y --force-yes
apt-get install -y build-essential software-properties-common python-software-properties

#
# Setup locales
#
echo -e "LC_CTYPE=en_GB.UTF-8\nLC_ALL=en_GB.UTF-8\nLANG=en_GB.UTF-8\nLANGUAGE=en_GB.UTF-8" | tee -a /etc/environment &>/dev/null
locale-gen en_GB en_GB.UTF-8
dpkg-reconfigure locales

#
# Base system
#
apt-get -q -y install
  memcached \
  postgresql-9.4 \
  sqlite3 \
  beanstalkd \
  libyaml-dev \
  libsodium-dev \
  curl \
  htop \
  git \
  dos2unix \
  unzip \
  vim \
  grc \
  gcc \
  make \
  re2c \
  libpcre3 \
  libpcre3-dev \
  lsb-core \
  autoconf \
  redis-server \
  redis-tools

#
# Base PHP
#
apt-get install -y --no-install-recommends \
  php7.0 \
  php7.0-apcu \
  php7.0-bcmath \
  php7.0-bz2 \
  php7.0-cli \
  php7.0-curl \
  php7.0-dba \
  php7.0-dev \
  php7.0-dom \
  php7.0-gd \
  php-pear \
  php7.0-igbinary \
  php7.0-intl \
  php7.0-imagick \
  php7.0-imap \
  php7.0-mbstring \
  php7.0-mcrypt \
  php7.0-memcached \
  php7.0-memcache \
  php7.0-pgsql \
  php7.0-redis \
  php7.0-sqlite3 \
  php7.0-soap \
  php7.0-xdebug \
  php7.0-xsl \
  php7.0-xml \
  php7.0-zip

#
# Update PECL channel
#
pecl channel-update pecl.php.net

#
# Nginx
#

cp -f /vagrant/vagrant/nginx.conf /etc/nginx/sites-enabled/nginx.conf

#
# Tune Up Postgres
#
cp /etc/postgresql/9.4/main/pg_hba.conf /etc/postgresql/9.4/main/pg_hba.bkup.conf
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres'" &>/dev/null
sed -i.bak -E 's/local\s+all\s+postgres\s+peer/local\t\tall\t\tpostgres\t\ttrust/g' /etc/postgresql/9.4/main/pg_hba.conf

#
# YAML
#
(CFLAGS="-O1 -g3 -fno-strict-aliasing"; pecl install yaml < /dev/null &)
touch /etc/php/7.0/mods-available/yaml.ini
echo 'extension = yaml.so' | tee /etc/php/7.0/mods-available/yaml.ini &>/dev/null

#
# Libsodium
#
pecl install -a libsodium < /dev/null &
touch /etc/php/7.0/mods-available/libsodium.ini
echo 'extension=libsodium.so' | tee /etc/php/7.0/mods-available/libsodium.ini &>/dev/null

#
# Zephir
#
echo "export ZEPHIRDIR=/usr/share/zephir" >> /home/vagrant/.profile
sudo mkdir -p ${ZEPHIRDIR}
(cd /tmp && git clone git://github.com/phalcon/zephir.git && cd zephir && ./install -c)
sudo chown -R vagrant:vagrant ${ZEPHIRDIR}

#
# Install Phalcon Framework
#
git clone --depth=1 git://github.com/phalcon/cphalcon.git
(cd cphalcon && zephir fullclean && zephir builddev)
touch /etc/php/7.0/mods-available/phalcon.ini
echo -e "extension=phalcon.so" | tee /etc/php/7.0/mods-available/phalcon.ini &>/dev/null

#
# Tune Up Redis
#
cp /etc/redis/redis.conf /etc/redis/redis.bkup.conf
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf

#
# Composer for PHP
#
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#
# Install Phalcon DevTools
#
cd ~
phpdismod -v 7.0 xdebug
echo '{"require": {"phalcon/devtools": "dev-master"}}' > composer.json
composer install --ignore-platform-reqs
rm composer.json
mkdir /opt/phalcon-tools
mv ~/vendor/phalcon/devtools/* /opt/phalcon-tools
rm -rf ~/vendor
echo "export PTOOLSPATH=/opt/phalcon-tools/" >> /home/vagrant/.profile
echo "export PATH=\$PATH:/opt/phalcon-tools/" >> /home/vagrant/.profile
chmod +x /opt/phalcon-tools/phalcon.sh
ln -s /opt/phalcon-tools/phalcon.sh /usr/bin/phalcon

#
# Tune UP PHP
#
echo 'apc.enable_cli = 1' | tee -a /etc/php/7.0/mods-available/apcu.ini &>/dev/null
phpenmod -v 7.0 yaml mcrypt intl curl libsodium phalcon xdebug soap

#
#  Cleanup
#
apt-get autoremove -y
apt-get autoclean -y

echo -e "----------------------------------------"
echo -e "To create a Phalcon Project:\n"
echo -e "----------------------------------------"
echo -e "$ cd /vagrant/www"
echo -e "$ phalcon project <projectname>\n"
echo -e
echo -e "Then follow the README.md to copy/paste the VirtualHost!\n"

echo -e "----------------------------------------"
echo -e "Default Site: http://192.168.50.4"
echo -e "----------------------------------------"
