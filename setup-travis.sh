#!/bin/bash

set -o errexit

KONG_VERSION=$1

echo "Installing Kong version: $KONG_VERSION"

# Installing other dependencies
sudo apt-get update
sudo apt-get install -y git curl make pkg-config unzip libpcre3-dev apt-transport-https


####################
# Install Postgres #
####################

# Create PG user and database
psql -U postgres <<EOF
\x
CREATE USER kong;
CREATE DATABASE kong OWNER kong;
CREATE DATABASE kong_tests OWNER kong;
EOF

################
# Install Kong #
################
echo Fetching and installing Kong...
wget -q -O kong.deb https://github.com/Mashape/kong/releases/download/$KONG_VERSION/kong-$KONG_VERSION.trusty_all.deb
sudo apt-get update
sudo apt-get install -y netcat openssl libpcre3 dnsmasq procps perl
sudo dpkg -i kong.deb
rm kong.deb

# Adjust PATH
export PATH=$PATH:/usr/local/bin:/usr/local/openresty/bin

# Prepare path to lua libraries
ln -sfn /usr/local $HOME/.luarocks

# Set higher ulimit
sudo bash -c 'echo "fs.file-max = 65536" >> /etc/sysctl.conf'
sudo sysctl -p
sudo bash -c "cat >> /etc/security/limits.conf" << EOL
* soft     nproc          65535
* hard     nproc          65535
* soft     nofile         65535
* hard     nofile         65535
EOL

# Workaround for lua
sudo chown -R $USER /usr/local

#############
# Finish... #
#############

# Adjust LUA_PATH to find the plugin dev setup
export LUA_PATH="/kong-plugin/?.lua;/kong-plugin/?/init.lua;;"

echo "Successfully Installed Kong version: $KONG_VERSION"
