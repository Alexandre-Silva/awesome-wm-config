-- local awful = require("awful")
-- local config_path = awful.util.getdir("config")
config_path = "./"

local resources = {}

local find_template = 'find %s -type f -name *.png'

function scandir(directory)
  local i, t, popen = 0, {}, io.popen
  local pfile = popen(string.format(find_template, director, directoryy))
  for filename in pfile:lines() do
    i = i + 1
    t[i] = filename
  end
  pfile:close()
  return t
end

for _,v in ipairs(scandir("icons")) do
  print(v)
end

return resources
