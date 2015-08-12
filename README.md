# ![json.lua](https://cloud.githubusercontent.com/assets/3920290/9207222/24413cbe-4064-11e5-874e-7e2deeb5f8cb.png)  
A minimal JSON library for Lua


## Features
* Pure Lua implementation
* Tiny: around 270sloc, 8kb
* Proper error messages, *eg:* `expected '}' or ',' at line 203 col 30`


## Usage
The [json.lua](json.lua?raw=1) file should be dropped into an existing project
and required by it:
```lua
json = require "json"
```
The library provides the following functions:

#### json.encode(value)
Returns a string representing `value` encoded in JSON.
```lua
json.encode({ 1, 2, 3, { x = 10 } }) -- Returns '[1,2,3,{"x":10}]'
```

#### json.decode(str)
Returns a value representing the decoded JSON string.
```lua
json.decode('[1,2,3,{"x":10}]') -- Returns { 1, 2, 3, { x = 10 } }
```

## Notes
* Tables with the key `1` set are treated as arrays when encoding
* `null` values contained within an array or object are converted to `nil` and
  are therefore lost upon decoding
* *Pretty* encoding is not supported, `json.encode()` only encodes to a compact
  format


## License
This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.

