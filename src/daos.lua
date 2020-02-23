-- daos.lua
local typedefs = require "kong.db.schema.typedefs"


return {
  -- this plugin only results in one custom DAO, named `jwt_crafter`:
  jwt_crafter = {
    name                  = "jwt_crafter_totp_token", -- the actual table in the database
    -- endpoint_key          = "consumer",
    primary_key           = { "id" },
    cache_key             = { "consumer" },
    generate_admin_api    = true,
    admin_api_name        = "totp-tokens",
    admin_api_nested_name = "totp-token",    
    fields = {
      {
        -- a value to be inserted by the DAO itself
        -- (think of serial id and the uniqueness of such required here)
        id = typedefs.uuid,
      },
      {
        -- also interted by the DAO itself
        created_at = typedefs.auto_timestamp_s,
      },
      {
        -- a foreign key to a consumer's id
        consumer = {
          type      = "foreign",
          reference = "consumers",
          required = true,
          unique = true,
          on_delete = "cascade",
        },
      },
      {
        -- the totp token
        totp_token = {
          type      = "string",
          required  = true,
        },
      },
    },
  },
}