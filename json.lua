--
-- json.lua
--
-- Copyright (c) 2015 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local json = { _version = "0.0.0" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local loadstring = loadstring or load
local encode

local escape_char_map = {
  [ "\\" ] = "\\\\",
  [ "\"" ] = "\\\"",
  [ "\b" ] = "\\b",
  [ "\f" ] = "\\f",
  [ "\n" ] = "\\n",
  [ "\r" ] = "\\r",
  [ "\t" ] = "\\t",
}

local function escape_char(c)
  return escape_char_map[c] or string.format("\\u%04x", c:byte())
end


local function encode_nil(val)
  return "null"
end 


local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  if val[1] ~= nil then
    -- Treat as an array
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    -- Treat as an object
    for k, v in pairs(val) do
      local t = type(k)
      if t ~= "string" then
        error("expected key of type 'string', got '" .. t .. "'")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end


local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return tostring(val)
end


local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}


encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end


function json.encode(val)
  return ( encode(val) )
end


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...) 
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local keywords      = create_set("true", "false", "null")


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function parse_unicode_escape(s)
  local n = tonumber( s:sub(3), 16 )
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(n / 64 + 192, n % 64 + 128)
  end
  return string.char(n / 4096 + 224, n % 4096 / 64 + 128, n % 64 + 128)
end


local function parse_string(str, i, chr)
  local has_unicode_escape = false
  local last
  for j = i + 1, #str do
    local x = str:sub(j, j)

    if x == "\n" then
      decode_error(str, j, "unexpected new line in string")
    end

    if last == "\\" then
      if x == "u" then 
        local hex = str:sub(j + 1, j + 5)
        if not hex:find("%x%x%x%x") then
          decode_error(str, j, "invalid unicode escape in string")
        end
        if hex:find("^[dD][89aAbB]") then
          decode_error(str, j, "unsupported utf-16 surrogate pair in string")
        end
        has_unicode_escape = true
      end
      if not escape_chars[x] then
        decode_error(str, j, "invalid escape char '" .. x .. "' in string")
      end

    elseif x == '"' then
      local s = str:sub(i, j)
      if has_unicode_escape then 
        s = s:gsub("\\u....", parse_unicode_escape)
      end
      return loadstring( "return " .. s )(), j + 1
    end
    last = x
  end
  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i, chr)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end


local function parse_keyword(str, i, chr)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not keywords[word] then
    decode_error(str, i, "invalid keyword '" .. word .. "'")
  end
  return (chr == "t") and true or (chr == "f") and false, x
end


local function parse_array(str, i, chr)
  local res = {}
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then 
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token 
    i = next_char(str, i, space_chars, true)
    chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end


local function parse_object(str, i, chr)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then 
      i = i + 1
      break
    end
    -- Read key
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end


local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "." ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_keyword,
  [ "f" ] = parse_keyword,
  [ "n" ] = parse_keyword,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}


parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx, chr)
  else
    decode_error(str, idx, "unexpected character '" .. chr .. "'")
  end
end


function json.decode(str)
  return ( parse(str, next_char(str, 1, space_chars, true)) )
end


return json
