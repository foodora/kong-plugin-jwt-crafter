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
    ["kong.plugins.jwt-crafter.schema"] = "src/schema.lua",
  }
}
