package = "kong-lua-sandbox"

version = "1.0.0-0"

source = {
   url = "git://github.com/kong/kong-lua-sandbox.git",
   tag = "v1.0.0"
}

description = {
   summary = "A pure-lua solution for running untrusted Lua code.",
   homepage = "https://github.com/kong-lua-sandbox",
}

dependencies = {
   "lua >= 5.1",
}

build = {
   type = "builtin",
   modules = {
      ["kong-lua-sandbox"] = "kong-lua-sandbox.lua",
   }
}
