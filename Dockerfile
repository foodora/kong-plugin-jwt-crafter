ARG kong_version
FROM kong:${kong_version} as base

USER root

ADD ./kong-plugin-jwt-crafter-1.2-0.rockspec .
ADD ./src ./src

RUN apk add build-base
RUN luarocks install luaossl OPENSSL_DIR=/usr/local/kong/ CRYPTO_INCDIR=/usr/local/kong/include
RUN luarocks make && luarocks pack kong-plugin-jwt-crafter

RUN rm kong-plugin-jwt-crafter-1.2-0.rockspec && rm -r src
RUN apk del build-base

FROM tianon/true

COPY --from=base ./kong-plugin-jwt-crafter-1.2-0.all.rock /
