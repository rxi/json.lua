local bench = require "util.bench"


local libs = {
  "../json.lua",    -- https://github.com/rxi/json.lua
  "dkjson.lua",     -- https://github.com/LuaDist/dkjson
  "jfjson.lua",     -- http://regex.info/blog/lua/json
  "json4lua.lua",   -- https://github.com/craigmj/json4lua
}


-- Build table which will be encoded: wikipedia example stored 1000 times
local data = {}
for i = 1, 1000 do
  table.insert(data, {
    firstName = "John",
    lastName = "Smith",
    isAlive = true,
    age = 25,
    address = {
      streetAddress = "21 2nd Street",
      city = "New York",
      state = "NY",
      postalCode = "10021-3100"
    },
    phoneNumbers = {
      { type = "home", number = "212 555-1234" },
      { type = "office", number = "646 555-4567" }
    },
    children = {},
    spouse = nil
  })
end


-- Run benchmarks
local results = {}

for i, name in ipairs(libs) do
  local f = loadfile(name)
  if not f then 
    error( "failed to load '" .. name ..  "'; run './get_json_libs.sh'" )
  end
  local json = f()

  -- Handle special cases
  if name == "jfjson.lua" then
    local _encode, _decode = json.encode, json.decode
    json.encode = function(...) return _encode(json, ...) end
    json.decode = function(...) return _decode(json, ...) end
  end

  -- Warmup (for LuaJIT)
  bench.run(name, 1, function() json.encode(data) end)

  -- Run and push results
  local res = bench.run(name, 10, function() json.encode(data) end)
  table.insert(results, res)
end


bench.print_system_info()
bench.print_results(results)
