# JWT Crafter Kong plugin

This plugin adds the possibility to generate a JWT token within Kong itself, eliminating the need for a upstream service doing the token generation.

The JWT plugin included in Kong has two main features: storing JWT secrets per consumer and verifying tokens when proxying to upstream services. It is missing the capability to generate a token based on succesful authentication.

This plugin needs two other plugins to work:
 - the JWT plugin itself, it uses it to fetch the JWT credential where the signing secret is stored
 - any authentication plugin (e.g. Basic Auth, JWT, OAuth2), a consumer must be authenticated to generate a token

## Example

Create an API and a consumer with a JWT credential (not token), add Basic auth to the API:

```bash
curl -XPOST -H 'Content-Type: application/json' -d '{"uris": "/sign_in", "upstream_url": "http://localhost", "name": "sign_in_api"}' localhost:8001/apis
curl -XPOST -H 'Content-Type: application/json' -d '{"username": "test"}' localhost:8001/consumers
curl -XPOST -H 'Content-Type: application/json' localhost:8001/consumers/{consumer_id_from_above}/jwt
curl -XPOST -d 'username=user' -d 'password=pass' localhost:8001/consumers/{consumer_id_from_above}/basic-auth
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

## Installation

## Configuration

All configuration options are optional

| key               | default value | description |
| expires_in        | 8 * 60 * 60   | validity of token in seconds |

## Limitations

Currently, the plugin loads the first HS256 JWT credential of the consumer. It does not include other signing algorithms or specifying which JWT credential to use for signing the key.
