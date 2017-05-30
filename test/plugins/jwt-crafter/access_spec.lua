local helpers = require "spec.helpers"
local cjson = require "cjson"
local meta = require "kong.meta"
local utils = require "kong.tools.utils"

describe("Plugin: jwt-crafter (access)", function()

  local client

  setup(function()
    local api1 = assert(helpers.dao.apis:insert {
      name = "api-1",
      hosts = { "basic-auth1.com" },
      upstream_url = "http://mockbin.com"
    })
    assert(helpers.dao.plugins:insert {
      name = "basic-auth",
      api_id = api1.id
    })

    local api2 = assert(helpers.dao.apis:insert {
      name = "api-2",
      hosts = { "basic-auth2.com" },
      upstream_url = "http://mockbin.com"
    })
    assert(helpers.dao.plugins:insert {
      name = "basic-auth",
      api_id = api2.id,
      config = {
        hide_credentials = true
      }
    })

    local consumer = assert(helpers.dao.consumers:insert {
      username = "bob"
    })
    local anonymous_user = assert(helpers.dao.consumers:insert {
      username = "no-body"
    })
    assert(helpers.dao.basicauth_credentials:insert {
      username = "bob",
      password = "kong",
      consumer_id = consumer.id
    })
     assert(helpers.dao.basicauth_credentials:insert {
      username = "user123",
      password = "password123",
      consumer_id = consumer.id
    })

    local api3 = assert(helpers.dao.apis:insert {
      name = "api-3",
      hosts = { "basic-auth3.com" },
      upstream_url = "http://mockbin.com"
    })
    assert(helpers.dao.plugins:insert {
      name = "basic-auth",
      api_id = api3.id,
      config = {
        anonymous = anonymous_user.id
      }
    })

    local api4 = assert(helpers.dao.apis:insert {
      name = "api-4",
      hosts = { "basic-auth4.com" },
      upstream_url = "http://mockbin.com"
    })
    assert(helpers.dao.plugins:insert {
      name = "basic-auth",
      api_id = api4.id,
      config = {
        anonymous = utils.uuid() -- a non-existing consumer id
      }
    })

    assert(helpers.start_kong())
    client = helpers.proxy_client()
  end)


  teardown(function()
    if client then client:close() end
    helpers.stop_kong()
  end)


  describe("Unauthorized", function()

    it("returns Unauthorized on missing credentials", function()
      local res = assert(client:send {
        method = "GET",
        path = "/status/200",
        headers = {
          ["Host"] = "basic-auth1.com"
        }
      })
      local body = assert.res_status(401, res)
      local json = cjson.decode(body)
      assert.same({ message = "Unauthorized" }, json)
    end)
  end)
end)
