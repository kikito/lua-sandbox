package = "sandbox"

version = "1.0.1-4"

source = {
   url = "git+https://github.com/kikito/lua-sandbox",
   tag = "v1.0.1"
}

description = {
   summary = "A pure-lua solution for running untrusted Lua code.",
   homepage = "https://github.com/kikito/lua-sandbox",
}

dependencies = {
   "lua >= 5.1",
}

build = {
   type = "builtin",
   modules = {
      ["sandbox"] = "sandbox.lua",
   }
}
