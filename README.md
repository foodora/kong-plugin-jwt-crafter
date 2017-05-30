# JWT Crafter Kong plugin

[![Build Status](https://travis-ci.org/foodora/kong-plugin-jwt-crafter.svg?branch=master)](https://travis-ci.org/foodora/kong-plugin-jwt-crafter)

This plugin adds the possibility to generate a JWT token within Kong itself, eliminating the need for a upstream service doing the token generation.

The JWT plugin included in Kong has two main features: storing JWT secrets per consumer and verifying tokens when proxying to upstream services. It is missing the capability to generate a token based on successful authentication.

This plugin needs two other plugins to work:
 - the JWT plugin itself, it uses it to fetch the JWT credential where the consumer's signing secret is stored
 - any authentication plugin (e.g. Basic authentication, JWT, OAuth2); a consumer must be authenticated to generate a token

It also uses the ACL plugin and embeds all the consumer ACLs inside the token claims section. Upstream services can then decode the token and use the ACLs from the token to authorize users within app code.

Tests run against Kong 0.9.x and 0.10.x.

## Example

Create an API and a consumer with a JWT credential (not token), add Basic auth to the API:

```bash
# Create sign in API
curl -XPOST -H 'Content-Type: application/json' -d '{"uris": "/sign_in", "upstream_url": "http://localhost", "name": "sign_in_api"}' localhost:8001/apis

# Create consumer
curl -XPOST -H 'Content-Type: application/json' -d '{"username": "test"}' localhost:8001/consumers

# Create JWT credential for consumer
curl -XPOST -H 'Content-Type: application/json' localhost:8001/consumers/{consumer_id_from_above}/jwt

# Create basic auth credentials for consumer
curl -XPOST -d 'username=user' -d 'password=pass' localhost:8001/consumers/{consumer_id_from_above}/basic-auth

# Enable basic auth for sign in API
curl -XPOST -d 'name=basic-auth' localhost:8001/apis/{api_id_from_above}/plugins
```

Note: the upstream_url of the API is irrelevant, the plugin short circuits the response and returns the token directly from Kong. Just make sure to enter a URL which can resolve on DNS, otherwise Kong complains. This is a known limitation of Kong.

Enable the JWT crafter plug-in:
```bash
curl -X POST -d 'name=jwt-crafter' localhost:8001/apis/{api_id_from_above}/plugins
```

Putting it all together, calling the created API authenticated using Basic authentication will yield the following response:

```bash
# user:pass is base64 encoded
curl -H 'Authorization: basic dGVzdDp0ZXN0' localhost:8000/sign_in
```

```json
{
  "token_type": "Bearer",
  "expires_in": 28800,
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW0iOiJ0ZXN0Iiwic3ViIjoiYzNiODMzMDgtMWYyNS00M2VmLWExN2MtOWNjNTBlOGI3OWQ2IiwiaXNzIjoiNmIzOWYzNzhjNzQzNGUyMmIzZjg4N2Q2ZTMzNDgwOTkiLCJleHAiOjE0OTU5MTAwODMsInJvbCI6WyJhYWEiLCJiYmIiXX0.yMufTuFi7aKpJeDYGiiR0en035w3G_MNHtQO4xkIKdU"
}
```

Decoded token:
```js
{
  "alg": "HS256",
  "typ": "JWT"
}
{
  "nam": "test", // Credential username or user ID
  "sub": "c3b83308-1f25-43ef-a17c-9cc50e8b79d6", // Consumer ID
  "iss": "6b39f378c7434e22b3f887d6e3348099", // JWT credential key (issuer)
  "exp": 1495910051, // Valid until
  "rol": [ // ACLs of the consumer from Kong
    "aaa",
    "bbb"
  ]
}
```

## Installation

Install the rock when building your Kong image/instance:
```
luarocks install kong-plugin-jwt-crafter
```

Add the plugin to your `custom_plugins` section in `kong.conf`, the `KONG_CUSTOM_PLUGINS` is also available.

```
custom_plugins = jwt-crafter
```

## Configuration

All configuration options are optional

| key               | default value | description |
|-------------------|---------------|-------------|
| expires_in        | 8 * 60 * 60   | validity of token in seconds |

## Limitations

Currently, the plugin loads the first HS256 JWT credential of the consumer. It does not include other signing algorithms or a possibility to specify which consumer JWT credential should be used to sign the key if the consumer has multiple credentials.
