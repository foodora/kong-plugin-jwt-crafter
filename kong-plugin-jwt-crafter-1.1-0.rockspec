package = "kong-plugin-jwt-crafter"
version = "1.1-0"

source = {
  url = "git://github.com/nextpertise/kong-plugin-jwt-crafter",
  tag = "v1.1"
}

description = {
  summary = "Crafts JWT plugin for succesfully authenticated requests based on consumer JWT credential.",
  license = "MIT"
}

dependencies = {
  "lua ~> 5.1"
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.jwt-crafter.handler"] = "src/handler.lua",
    ["kong.plugins.jwt-crafter.groups"] = "src/groups.lua",
    ["kong.plugins.jwt-crafter.jwt"] = "src/jwt.lua",
    ["kong.plugins.jwt-crafter.totp"] = "src/totp.lua",
    ["kong.plugins.jwt-crafter.schema"] = "src/schema.lua",
    ["kong.plugins.jwt-crafter.daos"] = "src/daos.lua",
    ["kong.plugins.jwt-crafter.migrations.init"] = "src/migrations/init.lua",
    ["kong.plugins.jwt-crafter.migrations.000_base_jwt_crafter"] = "src/migrations/000_base_jwt_crafter.lua",
  }
}
