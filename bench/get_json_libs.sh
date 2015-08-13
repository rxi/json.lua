#!/bin/bash
# Downloads other JSON libraries for use in the benchmark scripts

# Remove libraries
rm dkjson.lua   2>/dev/null
rm jfjson.lua   2>/dev/null
rm json4lua.lua 2>/dev/null

# Get libraries
echo "Downloading json libs..."
curl -sS -o dkjson.lua    "https://raw.githubusercontent.com/LuaDist/dkjson/master/dkjson.lua"
curl -sS -o json4lua.lua  "https://raw.githubusercontent.com/craigmj/json4lua/master/json/json.lua"
curl -sS -o jfjson.lua    "http://regex.info/code/JSON.lua"

echo "Done"
