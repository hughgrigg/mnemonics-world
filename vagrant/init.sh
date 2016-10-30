#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

export DEBIAN_FRONTEND=noninteractive
export COMPOSER_ALLOW_SUPERUSER=1
export ZEPHIRDIR=/usr/share/zephir

#
# Add Swap
#
sudo dd if=/dev/zero of=/swapspace bs=1M count=4000
sudo mkswap /swapspace
sudo swapon /swapspace
echo "/swapspace none swap defaults 0 0" >> /etc/fstab

echo nameserver 8.8.8.8 > /etc/resolv.conf
echo nameserver 8.8.4.4 > /etc/resolv.conf

apt-get update --quiet --fix-missing
apt-get dist-upgrade --quiet --yes \
    -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

#
# Add PHP, PostgreSQL and Nginx repositories
#
add-apt-repository -y ppa:ondrej/php
apt-add-repository -y ppa:chris-lea/libsodium
add-apt-repository -y ppa:chris-lea/redis-server
touch /etc/apt/sources.list.d/pgdg.list
echo -e "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" | tee -a /etc/apt/sources.list.d/pgdg.list &>/dev/null
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/nginx-stable.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C

# Cleanup package manager
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

apt-key update
apt-get update -qq
apt-get upgrade -y --force-yes
apt-get install -y build-essential software-properties-common python-software-properties

#
# Base system
#
apt-get --quiet --yes --force-yes \
  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  install \
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
  redis-tools \
  nginx

#
# Base PHP
#
apt-get --quiet --yes --force-yes --no-install-recommends \
  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  install \
  php7.0 \
  php7.0-fpm \
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
  php7.0-zip \
  php7.0-yaml

#
# Update PECL channel
#
pecl channel-update pecl.php.net

#
# Nginx
#
cp -f /vagrant/mnemonicsworld/vagrant/mnemonicsworld.conf /etc/nginx/sites-enabled/mnemonicsworld.conf
mkdir /etc/nginx/ssl 2>/dev/null

PATH_SSL="/etc/nginx/ssl"
PATH_KEY="${PATH_SSL}/mnemonicsworld.key"
PATH_CSR="${PATH_SSL}/mnemonicsworld.csr"
PATH_CRT="${PATH_SSL}/mnemonicsworld.crt"

if [ ! -f $PATH_KEY ] || [ ! -f $PATH_CSR ] || [ ! -f $PATH_CRT ]
then
  openssl genrsa -out "$PATH_KEY" 2048 2>/dev/null
  openssl req -new -key "$PATH_KEY" -out "$PATH_CSR" -subj "/CN=mnemonicsworld/O=Vagrant/C=UK" 2>/dev/null
  openssl x509 -req -days 365 -in "$PATH_CSR" -signkey "$PATH_KEY" -out "$PATH_CRT" 2>/dev/null
fi

#
# Tune Up Postgres
#
cp /etc/postgresql/9.4/main/pg_hba.conf /etc/postgresql/9.4/main/pg_hba.bkup.conf
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres'" &>/dev/null
sed -i.bak -E 's/local\s+all\s+postgres\s+peer/local\t\tall\t\tpostgres\t\ttrust/g' /etc/postgresql/9.4/main/pg_hba.conf

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
echo -e "extension=phalcon.so" | tee /etc/php/7.0/fpm/conf.d/23-phalcon.ini &>/dev/null

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
