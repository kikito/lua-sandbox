local BASE_ENV = {}

([[
  assert ipairs next pairs pcall tonumber tostring unpack select type _VERSION xpcall

  string.byte string.char string.find string.format string.gmatch string.gsub
  string.len string.lower string.match string.reverse string.sub string.upper

  table.insert table.maxn table.remove table.sort

  math.abs math.acos math.asin math.atan math.atan2 math.ceil math.cos
  math.cosh math.deg math.exp math.foor math.fmod math.frexp math.huge
  math.ldexp math.log math.log10 math.max math.min math.modf math.pi
  math.pow math.rad math.random math.sin math.sinh math.sqrt math.tan
  math.tanh

  os.clock os.difftime os.time
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


local function run(f, options)
  if type(f) == 'string' then f = loadstring(f) end

  string.rep = nil
  setfenv(f, BASE_ENV)
  local result = f()

  string.rep = string_rep

  return result
end

local sandbox = { run = run }


return setmetatable(sandbox, {__call = function(_,f) return run(f) end})
