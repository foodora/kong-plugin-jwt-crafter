-- daos.lua
local typedefs = require "kong.db.schema.typedefs"


return {
  -- this plugin only results in one custom DAO, named `jwt_crafter`:
  jwt_crafter = {
    name                  = "jwt_crafter_totp_keys", -- the actual table in the database
    endpoint_key          = "consumer_uniq",
    primary_key           = { "id" },
    cache_key             = { "consumer_uniq" },
    generate_admin_api    = true,
    admin_api_name        = "totp-keys",
    admin_api_nested_name = "totp-key",    
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
          on_delete = "cascade",
        },
      },
      {
        -- the consumer_uniq hack, supply any value, transformations will rewrite this to consumer.id
        consumer_uniq = {
          type      = "string",
          unique = true,
          required  = true,
        },
      },
      {
        -- the totp key
        totp_key = {
          type      = "string",
          required  = true,
        },
      },
    },
    transformations = {
      {
        input = { "consumer_uniq" },
        needs = { "consumer.id" },
        on_write = function(consumer_uniq, consumer_id)
          return { consumer_uniq = consumer_id }
        end,
      },
    },
  },
}