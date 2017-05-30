local singletons = require "kong.singletons"
local responses = require "kong.tools.responses"

local table_insert = table.insert
local table_concat = table.concat

local jwt = require "resty.jwt"
local cjson = require "cjson"

local BasePlugin = require "kong.plugins.base_plugin"
local JwtCrafter = BasePlugin:extend()

JwtCrafter.PRIORITY = 10

function JwtCrafter:new()
  JwtCrafter.super.new(self, "jwt-crafter")
end

local function fetch_acls(consumer_id)
  local results, err = singletons.dao.acls:find_all {consumer_id = consumer_id}
  if err then
    return nil, err
  end
  return results
end

local function load_credential(consumer_id)
  -- Only HS256 is now supported, probably easy to add more if needed
  local rows, err = singletons.dao.jwt_secrets:find_all {consumer_id = consumer_id, algorithm = "HS256"}
  if err then
    return nil, err
  end
  return rows[1]
end

-- Executed for every request upon it's reception from a client and before it is being proxied to the upstream service.
function JwtCrafter:access(config)
  JwtCrafter.super.access(self)

  local consumer_id
  if ngx.ctx.authenticated_credential then
    consumer_id = ngx.ctx.authenticated_credential.consumer_id
  else
    return responses.send_HTTP_FORBIDDEN("Cannot identify the consumer, add an authentication plugin to generate JWT token")
  end

  local acls, err = fetch_acls(consumer_id)

  if err then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end
  if not acls then acls = {} end

  -- Prepare header
  local str_acls = {}
  for _, v in ipairs(acls) do
    table_insert(str_acls, v.group)
  end

  -- Fetch JWT secret for signing
  local credential, err = load_credential(consumer_id)

  if err then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end
  if not credential then
    return responses.send_HTTP_FORBIDDEN("Consumer has no JWT credential, cannot craft token")
  end

  -- Hooray, create the token finally
  local jwt_token = jwt:sign(
    credential.secret,
    {
      header = {
        typ = "JWT",
        alg = "HS256" -- load_credential only loads HS256 for now
      },
      payload = {
        sub = ngx.ctx.authenticated_consumer.id,
        nam = ngx.ctx.authenticated_credential.username or ngx.ctx.authenticated_credential.id,
        iss = credential.key,
        rol = str_acls,
        exp = ngx.time() + config.expires_in
      }
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
