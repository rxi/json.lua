local bench = {}

local unpack = unpack or table.unpack
local fmt = string.format


function bench.run(name, count, func)
  -- Run bench
  local res = {}
  for i = 1, count do
    local start_time = os.clock()
    func()
    table.insert(res, (os.clock() - start_time))
  end
  -- Calculate average
  local avg = 0
  for i, v in ipairs(res) do
    avg = avg + v
  end
  avg = avg / #res
  -- Build and return result table
  return {
    name = name,
    avg = avg,
    min = math.min(unpack(res)),
    max = math.max(unpack(res)),
    all = res,
  }
end


function bench.get_cpu_name()
  local fp = io.open("/proc/cpuinfo", "rb")
  if not fp then
    return "unknown"
  end
  local text = fp:read("*a")
  return text:match("model name%s*:%s*(.-)\n")
end


function bench.print_system_info()
  print( fmt("Lua version   : %s", jit and jit.version or _VERSION) )
  print( fmt("CPU name      : %s", bench.get_cpu_name()) )
end


function bench.print_results(results)
  -- Find best average
  local best = math.huge
  for i, v in ipairs(results) do
    best = math.min(best, v.avg)
  end
  -- Print results
  for i, v in ipairs(results) do
    print( fmt("%-13s : %.03gs [x%1.3g] (min: %.03gs, max %.03gs)",
               v.name, v.avg, v.avg / best, v.min, v.max) )
  end
end


return bench
