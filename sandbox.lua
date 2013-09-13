local BASE_ENV = {}
-- Non-safe :
-- * string.rep: can be used to allocate millions of bytes in 1 operation
-- * {set|get}metatable: can be used to modify the metatable of global objects (strings, integers)
-- * collectgarbage: can affect performance of other systems
-- * dofile: can access the server filesystem
-- * _G: Unsafe. It can be mocked though
-- * load{file|string}: All unsafe because they can grant acces to global env
-- * raw{get|set|equal}: Potentially unsafe
-- * module|require|module: Can modify the host settings
-- * string.dump: Can display confidential server info (implementation of functions)
-- * string.rep: Can allocate millions of bytes in one go
-- * math.randomseed: Can affect the host sytem
-- * io.*, os.*: Most stuff there is non-save

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


local string_rep = string.rep

local function merge(dest, source)
  for k,v in pairs(source) do
    dest[k] = dest[k] or v
  end
  return dest
end

local function cleanup()
  debug.sethook()
  string.rep = string_rep
end

local function protect(f, options)
  if type(f) == 'string' then f = assert(loadstring(f)) end

  options = options or {}

  local quota = options.quota or 500000
  local env   = merge(options.env or {}, BASE_ENV)

  setfenv(f, env)

  return function(...)
    local timeout = function()
      cleanup()
      error('Quota exceeded: ' .. tostring(quota))
    end

    debug.sethook(timeout, "", quota)
    string.rep = nil

    local ok, result = pcall(f, ...)

    cleanup()

    if not ok then error(result) end
    return result
  end
end

local function run(f, options, ...)
  return protect(f, options)(...)
end

return setmetatable({protect = protect, run = run}, {__call = function(_,f,o) return protect(f,o) end})
