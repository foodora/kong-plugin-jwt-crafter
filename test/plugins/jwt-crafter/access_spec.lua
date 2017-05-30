local helpers = require "spec.helpers"
local cjson = require "cjson"
local meta = require "kong.meta"
local utils = require "kong.tools.utils"
local jwt_parser = require "kong.plugins.jwt.jwt_parser"

describe("Plugin: jwt-crafter (access)", function()

  local client, consumer, jwt_secret

  local function has_value(tab, val)
    for index, value in ipairs(tab) do
      if value == val then
        return true
      end
    end

    return false
  end

  setup(function()
    local api1 = assert(helpers.dao.apis:insert {
      name = "no-auth-sign-in",
      hosts = { "jwt-crafter1.com" },
      upstream_url = "http://mockbin.com"
    })
    assert(helpers.dao.plugins:insert {
      name = "jwt-crafter",
      api_id = api1.id,
      config = {
        expires_in = 120
      }
    })

    local api2 = assert(helpers.dao.apis:insert {
      name = "sign-in",
      hosts = { "jwt-crafter2.com" },
      upstream_url = "http://mockbin.com"
    })
    assert(helpers.dao.plugins:insert {
      name = "jwt-crafter",
      api_id = api2.id,
      config = {
        expires_in = 120
      }
    })
    assert(helpers.dao.plugins:insert {
      name = "basic-auth",
      api_id = api2.id
    })

    consumer = assert(helpers.dao.consumers:insert {
      username = "bob_jwt"
    })

    local consumer_no_jwt = assert(helpers.dao.consumers:insert {
      username = "bob_nojwt"
    })

    jwt_secret = assert(helpers.dao.jwt_secrets:insert {
      consumer_id = consumer.id
    })

    assert(helpers.dao.acls:insert {
      consumer_id = consumer.id,
      group = "foo"
    })

    assert(helpers.dao.acls:insert {
      consumer_id = consumer.id,
      group = "bar"
    })

    assert(helpers.dao.basicauth_credentials:insert {
      username = "bob123",
      password = "password123",
      consumer_id = consumer.id
    })

    assert(helpers.dao.basicauth_credentials:insert {
      username = "bob_nojwt_123",
      password = "password123",
      consumer_id = consumer_no_jwt.id
    })

    assert(helpers.start_kong())
    client = helpers.proxy_client()
  end)


  teardown(function()
    if client then client:close() end
    helpers.stop_kong()
  end)


  describe("Missing API authentication", function()
    it("returns Forbidden", function()
      local res = assert(client:send {
        method = "GET",
        path = "/status/200",
        headers = {
          ["Host"] = "jwt-crafter1.com"
        }
      })
      local body = assert.res_status(403, res)
      local json = cjson.decode(body)
      assert.same({ message = "Cannot identify the consumer, add an authentication plugin to generate JWT token" }, json)
    end)
  end)

  describe("Missing JWT credential for consumer", function()
    it("returns Forbidden", function()
      local res = assert(client:send {
        method = "GET",
        path = "/status/200",
        headers = {
          ["Host"] = "jwt-crafter2.com",
          ["Authorization"] = "Basic Ym9iX25vand0XzEyMzpwYXNzd29yZDEyMw==" -- bob_nojwt_123:password123
        }
      })
      local body = assert.res_status(403, res)
      local json = cjson.decode(body)
      assert.same({ message = "Consumer has no JWT credential, cannot craft token" }, json)
    end)
  end)

  describe("Missing authentication for consumer", function()
    it("returns Forbidden", function()
      local res = assert(client:send {
        method = "GET",
        path = "/status/200",
        headers = {
          ["Host"] = "jwt-crafter2.com"
        }
      })
      local body = assert.res_status(401, res)
      local json = cjson.decode(body)
      assert.same({ message = "Unauthorized" }, json)
    end)
  end)

  describe("Valid authentication and credential", function()
    it("issues JWT token", function()
      local res = assert(client:send {
        method = "GET",
        path = "/status/200",
        headers = {
          ["Host"] = "jwt-crafter2.com",
          ["Authorization"] = "Basic Ym9iMTIzOnBhc3N3b3JkMTIz" -- bob123:password123
        }
      })
      local body = assert.res_status(200, res)
      local json = cjson.decode(body)
      assert.are.equals(120, json.expires_in)
      assert.are.equals("Bearer", json.token_type)

      local header, claims, signature = json.access_token:match("([^.]*).([^.]*).(.*)")
      header = cjson.decode(ngx.decode_base64(header))
      claims = cjson.decode(ngx.decode_base64(claims))

      assert.are.equals("HS256", header.alg)
      assert.are.equals("JWT", header.typ)

      assert.are.equals(consumer.id, claims.sub)
      assert.are.equals("bob123", claims.nam)
      assert.are.equals(jwt_secret.key, claims.iss)
      assert.is_true(has_value(claims.rol, "foo"))
      assert.is_true(has_value(claims.rol, "bar"))

      local jwt = assert(jwt_parser:new(json.access_token))
      assert.True(jwt:verify_signature(jwt_secret.secret))
    end)
  end)
end)
