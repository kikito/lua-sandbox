local BASE_ENV = {}

-- Non-safe :
-- string.rep: can be used to allocate millions of bytes in 1 operation
-- {set|get}metatable: can be used to modify the metatable of global objects (strings, integers)
-- collectgarbage: can affect performance of other systems
-- dofile: can access the server filesystem
-- _G: Unsafe. It can be mocked though
-- load{file|string}: All unsafe because they can grant acces to global env
-- raw{get|set|equal}: Potentially unsafe
-- module|require|package: Can modify the host settings
-- string.dump: Can display confidential server info (implementation of functions)
-- string.rep: Can allocate millions of bytes in one go
-- math.randomseed: Can affect the host sytem
-- io.*, os.*: Most stuff there is non-save

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
  local package, method = id:match('([^%.]+)%.([^%.]+)')
  if package then
    BASE_ENV[package]         = BASE_ENV[package] or {}
    BASE_ENV[package][method] = _G[package][method]
  else
    BASE_ENV[id] = _G[id]
  end
end)

local string_rep = string.rep

local function cleanup()
  debug.sethook()
  string.rep = string_rep
end

local function run(f, options)
  if type(f) == 'string' then f = assert(loadstring(f)) end

  options = options or {}

  local limit = options.limit or 500000

  setfenv(f, BASE_ENV)

  -- I would love to be able to make step greater than 1
  -- (say, 500000) but any value > 1 seems to choke with a simple while true do end
  -- After ~100 iterations, they stop calling timeout. So I need to use step = 1 and
  -- instructions_count the steps separatedly
  local step = 1
  local instructions_count = 0
  local timeout = function(str)
    instructions_count = instructions_count + 1
    if instructions_count >= limit then
      cleanup()
      error('Quota exceeded: ' .. tostring(instructions_count) .. '/' .. tostring(limit) .. ' instructions')
    end
  end
  debug.sethook(timeout, "", step)
  string.rep = nil

  local ok, result = pcall(f)

  cleanup()
  if not ok then error(result) end

  return result
end

return setmetatable({run = run}, {__call = function(_,f,o) return run(f,o) end})
