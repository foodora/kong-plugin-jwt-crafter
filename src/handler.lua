local groups = require "kong.plugins.jwt-crafter.groups"
local jwt = require "kong.plugins.jwt-crafter.jwt"
local totp = require "kong.plugins.jwt-crafter.totp"
local cjson = require "cjson"
local response = kong.response

local BasePlugin = require "kong.plugins.base_plugin"
local JwtCrafter = BasePlugin:extend()

JwtCrafter.PRIORITY = 10

function JwtCrafter:new()
  JwtCrafter.super.new(self, "jwt-crafter")
end

-- Executed for every request upon it's reception from a client and before it is being proxied to the upstream service.
function JwtCrafter:access(config)
  JwtCrafter.super.access(self)

  local consumer = kong.client.get_consumer()
  if consumer then
    local consumer_id = consumer.id
  else
    response.exit(403, "Cannot identify the consumer, make sure this user has Basic-Auth credentials")
  end

  -- Fetch JWT secret for signing
  local credential = jwt.load_credential(consumer.username)
  if err then
    return response.exit(500, err)
  end
  if not credential then
    response.exit(403, "Consumer has no JWT credential, cannot craft token")
  end

  -- Check if 2FA is enabled
  -- WIP if 2FA is enabled and 2FA token not supplied, return error
  -- WIP if 2FA is enabled and 2FA token supplied validate token, return error if token not valid
  -- <WIP>
  local totp_token
  totp_token = totp.load_totp_token(consumer.id)
  response.exit(599, "Token: " .. totp_token)
  -- </WIP>

  -- Hooray, create the token finally
  local jwt_token = jwt.encode_token(
    {
      sub = ngx.ctx.authenticated_consumer.id,
      nam = ngx.ctx.authenticated_credential.username or ngx.ctx.authenticated_credential.id,
      rol = groups.get_consumer_groups(consumer.id),
      iss = credential.key,
      exp = ngx.time() + config.expires_in
    },
    credential.secret,
    "HS256",
    {
      typ = "JWT",
      alg = "HS256" -- load_credential only loads HS256 for now
    }
  )

  ngx.say(
    cjson.encode(
      {
        access_token = jwt_token,
        token_type = "Bearer",
        expires_in = config.expires_in
      }
    )
  )
  ngx.exit(200)
end

return JwtCrafter
