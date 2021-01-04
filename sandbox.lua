local sandbox = {
  _VERSION      = "sandbox 0.5",
  _DESCRIPTION  = "A pure-lua solution for running untrusted Lua code.",
  _URL          = "https://github.com/kikito/sandbox.lua",
  _LICENSE      = [[
    MIT LICENSE

    Copyright (c) 2013 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}


-- PUC-Rio Lua 5.1 does not support deactivation of binary code
local mode_supported = _ENV or type(_G.jit) == "table"
sandbox.mode_supported = mode_supported

-- The base environment is merged with the given env option (or an empty table, if no env provided)
--
local BASE_ENV = {}

-- List of non-safe packages/functions:
--
-- * string.rep: can be used to allocate millions of bytes in 1 operation
-- * {set|get}metatable: can be used to modify the metatable of global objects (strings, integers)
-- * collectgarbage: can affect performance of other systems
-- * dofile: can access the server filesystem
-- * _G: It has access to everything. It can be mocked to other things though.
-- * load{file|string}: All unsafe because they can grant acces to global env
-- * raw{get|set|equal}: Potentially unsafe
-- * module|require|module: Can modify the host settings
-- * string.dump: Can display confidential server info (implementation of functions)
-- * string.rep: Can allocate millions of bytes in one go
-- * math.randomseed: Can affect the host sytem
-- * io.*, os.*: Most stuff there is non-save


-- Safe packages/functions below
([[

_VERSION assert error    ipairs   next pairs
pcall    select tonumber tostring type unpack xpcall

coroutine.create coroutine.resume coroutine.running coroutine.status
coroutine.wrap   coroutine.yield

math.abs   math.acos math.asin  math.atan math.atan2 math.ceil
math.cos   math.cosh math.deg   math.exp  math.fmod  math.floor
math.frexp math.huge math.ldexp math.log  math.log10 math.max
math.min   math.modf math.pi    math.pow  math.rad   math.random
math.sin   math.sinh math.sqrt  math.tan  math.tanh

os.clock os.difftime os.time

string.byte string.char  string.find  string.format string.gmatch
string.gsub string.len   string.lower string.match  string.reverse
string.sub  string.upper

table.insert table.maxn table.remove table.sort

]]):gsub('%S+', function(id)
  local module, method = id:match('([^%.]+)%.([^%.]+)')
  if module then
    BASE_ENV[module]         = BASE_ENV[module] or {}
    BASE_ENV[module][method] = _G[module][method]
  else
    BASE_ENV[id] = _G[id]
  end
end)

local function protect_module(module, module_name)
  return setmetatable({}, {
    __index = module,
    __newindex = function(_, attr_name, _)
      error('Can not modify ' .. module_name .. '.' .. attr_name .. '. Protected by the sandbox.')
    end
  })
end

('coroutine math os string table'):gsub('%S+', function(module_name)
  BASE_ENV[module_name] = protect_module(BASE_ENV[module_name], module_name)
end)

-- auxiliary functions/variables

local string_rep = string.rep

local function merge(dest, source)
  for k,v in pairs(source) do
    dest[k] = dest[k] or v
  end
  return dest
end

local function sethook(f, key, quota)
  if type(debug) ~= 'table' or type(debug.sethook) ~= 'function' then return end
  debug.sethook(f, key, quota)
end

local function cleanup()
  sethook()
  string.rep = string_rep
end

-- Public interface: sandbox.protect
function sandbox.protect(code, options)
  options = options or {}

  local quota = false
  if options.quota ~= false then
    quota = options.quota or 500000
  end

  local env   = merge(options.env or {}, BASE_ENV)
  env._G = env._G or env

  assert(type(code) == 'string', "expected a string")


  local f
  if mode_supported then
    f = assert(load(code, nil, options.mode, env))
  else
    if options.mode then
      error("options.mode is not supported on this environment (usually PUC-Rio Lua 5.1). Please unset options.mode")
    end
    f = assert(loadstring(code))
    setfenv(f, env)
  end

  return function(...)

    if quota then
      local timeout = function()
        cleanup()
        error('Quota exceeded: ' .. tostring(quota))
      end
      sethook(timeout, "", quota)
    end

    string.rep = nil

    local t = table.pack(pcall(f, ...))

    cleanup()

    if not t[1] then error(t[2]) end

    return table.unpack(t, 2, t.n)
  end
end

-- Public interface: sandbox.run
function sandbox.run(code, options, ...)
  return sandbox.protect(code, options)(...)
end

-- make sandbox(f) == sandbox.protect(f)
setmetatable(sandbox, {__call = function(_,code,o) return sandbox.protect(code,o) end})

return sandbox
