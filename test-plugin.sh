#!/bin/bash

export KONG_PLUGINS=bundled,jwt-crafter

cd /kong
bin/kong stop

kong migrations reset -y
kong migrations bootstrap

cd /kong-plugin/
luarocks make
cd /kong
bin/kong start

# Create service
curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data 'name=jwt-login' \
  --data 'url=http://neverinvoked/'

# Create route
curl -i -X POST \
  --url http://localhost:8001/services/jwt-login/routes \
  --data 'name=jwt-login-route' \
  --data 'paths=/jwt/log-in'

# Enable basic auth for service
curl -i -X POST http://localhost:8001/routes/jwt-login-route/plugins \
    --data "name=basic-auth"  \
    --data "config.hide_credentials=false"

# Enable basic auth for service
curl -i -X POST http://localhost:8001/routes/jwt-login-route/plugins \
    --data "name=jwt-crafter"  \
    --data "config.expires_in=86400"

# Add consumer
curl -i -X POST \
   --url http://localhost:8001/consumers/ \
   --data "username=testuser1"

# Add consumer group
curl -i -X POST \
   --url http://localhost:8001/consumers/testuser1/acls \
   --data "group=group1"

# Add consumer credentials
curl -i -X POST http://localhost:8001/consumers/testuser1/basic-auth \
    --data "username=testuser1" \
    --data "password=test"
curl -i -X POST http://localhost:8001/consumers/testuser1/jwt \
    --data "key=testuser1" \
    --data "algorithm=HS256"

curl -u testuser1:test http://localhost:8000/jwt/log-in

curl -i -X POST http://localhost:8001/consumers/testuser1/totp-token --data "totp_token=abc"

curl -i -X GET http://localhost:8001/consumers/testuser1/totp-token

# If you want to check your config in KONGA WebGUI
# cp /etc/kong/kong.conf.default /etc/kong/kong.conf
# in /etc/kong.conf:
# admin_listen = 127.0.0.1:8001 reuseport backlog=16384, 127.0.0.1:8444 http2 ssl reuseport backlog=16384
# -->
# admin_listen = 0.0.0.0:8001 reuseport backlog=16384, 127.0.0.1:8444 http2 ssl reuseport backlog=16384
# docker run -p 1337:1337 --name konga -e "NODE_ENV=production" -e "TOKEN_SECRET=fs7d86f78ds" pantsel/konga