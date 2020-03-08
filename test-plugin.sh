#!/bin/bash

export KONG_PLUGINS=bundled,jwt-crafter

cd /kong-plugin/
luarocks make

cd /kong
bin/kong stop

kong migrations reset -y
kong migrations bootstrap

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

# Add 2FA TOTP key
curl -s -X POST http://localhost:8001/consumers/testuser1/totp-key --data "consumer_uniq=true" --data "totp_key=JBSWY3DPEHPK3PXP" | jq .

# This should fail:
curl -u testuser1:test http://localhost:8000/jwt/log-in
# Response body
# Cannot verify the identify of the consumer, TOTP code is missing
#
# With X-TOTP header:
# $ curl -u testuser1:test -H 'X-TOTP: 790658' http://localhost:8000/jwt/log-in
# Generate TOTP timecode here, use key JBSWY3DPEHPK3PXP
# https://totp.danhersam.com/

# Get all TOTP keys from consumer
# $ curl -s -X GET http://localhost:8001/consumers/testuser1/totp-key
# Get TOTP key from consumer by id
# $ curl -s -X GET http://localhost:8001/consumers/testuser1/totp-key/f6969a94-ac0a-48e7-9c9a-d757f6d327b6
# Delete TOTP key from consumer by id
# $ curl -s -X DELETE http://localhost:8001/consumers/testuser1/totp-key/f6969a94-ac0a-48e7-9c9a-d757f6d327b6

# If you want to check your config in KONGA WebGUI
# cp /etc/kong/kong.conf.default /etc/kong/kong.conf
# in /etc/kong.conf:
# admin_listen = 127.0.0.1:8001 reuseport backlog=16384, 127.0.0.1:8444 http2 ssl reuseport backlog=16384
# -->
# admin_listen = 0.0.0.0:8001 reuseport backlog=16384, 127.0.0.1:8444 http2 ssl reuseport backlog=16384
# docker run -p 1337:1337 --name konga -e "NODE_ENV=production" -e "TOKEN_SECRET=fs7d86f78ds" pantsel/konga