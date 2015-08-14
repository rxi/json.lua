local bench = require "util.bench"


local libs = {
  "../json.lua",    -- https://github.com/rxi/json.lua
  "dkjson.lua",     -- https://github.com/LuaDist/dkjson
  "jfjson.lua",     -- http://regex.info/blog/lua/json
  --"json4lua.lua",   -- https://github.com/craigmj/json4lua
}


-- JSON string: wikipedia example stored 1000 times in an array
local text = "[" .. string.rep([[{
  "firstName": "John",
  "lastName": "Smith",
  "isAlive": true,
  "age": 25,
  "address": {
    "streetAddress": "21 2nd Street",
    "city": "New York",
    "state": "NY",
    "postalCode": "10021-3100"
  },
  "phoneNumbers": [
    {
      "type": "home",
      "number": "212 555-1234"
    },
    {
      "type": "office",
      "number": "646 555-4567"
    }
  ],
  "children": [],
  "spouse": null
}, ]], 1000):sub(1, -3) .. "]"


-- As this is meant to be a pure Lua benchmark, we remove the ability to
-- require 'lpeg' so dkjson doesn't use it for parsing. (Incidentally json.lua
-- seems to outperform libraries which use lpeg when both are using LuaJIT)
local _require = require
require = function(modname)
  if modname == "lpeg" then error() end
  return _require(modname)
end

-- Run benchmarks, store results
local results = {}

for i, name in ipairs(libs) do
  local f = loadfile(name)
  if not f then 
    error( "failed to load '" .. name ..  "'; run './get_json_libs.sh'" )
  end
  local json = f()

  -- Remap functions to work for jfjson.lua
  if name == "jfjson.lua" then
    local _encode, _decode = json.encode, json.decode
    json.encode = function(...) return _encode(json, ...) end
    json.decode = function(...) return _decode(json, ...) end
  end

  -- Warmup (for LuaJIT)
  bench.run(name, 1, function() json.decode(text) end)

  -- Run and push results
  local res = bench.run(name, 10, function() json.decode(text) end)
  table.insert(results, res)
end


bench.print_system_info()
bench.print_results(results)
