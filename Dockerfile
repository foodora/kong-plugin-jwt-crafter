ARG kong_version
FROM kong:${kong_version}

USER root

ADD ./kong-plugin-jwt-crafter-1.2-0.rockspec .
ADD ./src ./src

RUN luarocks make && luarocks pack kong-plugin-jsonrpc-request-transformer

RUN rm kong-plugin-jwt-crafter-1.2-0.rockspec && rm -r src

USER kong
