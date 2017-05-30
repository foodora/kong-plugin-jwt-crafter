local helpers = require "spec.helpers"
local cjson = require "cjson"
local meta = require "kong.meta"
local utils = require "kong.tools.utils"

describe("Plugin: jwt-crafter (access)", function()

  local client

  setup(function()
    local api1 = assert(helpers.dao.apis:insert {
      name = "no-auth-sign-in",
      hosts = { "jwt-crafter1.com" },
      upstream_url = "http://mockbin.com"
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

    local consumer = assert(helpers.dao.consumers:insert {
      username = "bob_jwt"
    })

    local consumer_no_jwt = assert(helpers.dao.consumers:insert {
      username = "bob_nojwt"
    })

    assert(helpers.dao.jwt_secrets:insert {
      consumer_id = consumer.id
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
    it("returns Unauthorized", function()
      local res = assert(client:send {
        method = "GET",
        path = "/status/200",
        headers = {
          ["Host"] = "jwt-crafter1.com"
        }
      })
      local body = assert.res_status(401, res)
      local json = cjson.decode(body)
      assert.same({ message = "Unauthorized" }, json)
    end)
  end)
end)
