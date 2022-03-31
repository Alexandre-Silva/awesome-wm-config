local naughty = require("naughty")
local awful = require("awful")
-- local ascreen = require("awful.screen")
local ascreen = awful.screen


local function pprint(v, offset)
  if offset == nil then
    offset = 0
  end

  local ident = ''
  for i=0, offset do
    ident = ident .. ' '
  end

  for k, v in pairs(v) do
    if type(v) == "table" then
      print(string.format('%s%s (table):', ident, k))
      pprint(v, offset+2)
    else
      print(string.format('%s%s: %s', ident, k, v))
    end
  end
end

local function log(v)
  naughty.notify(
    {
      title='tags',
      text=v,
      timeout=3,
  })
end



local screens={}
for i, s in ipairs(ascreen) do
  screens[i]=s
end

local focused = awful.screen.focused()

local function screen_name(screen)
  local geo = screen.geometry
  return '' .. geo.x .. 'x' .. geo.y .. '-' .. geo.width .. 'x' .. geo.height
end

if false then
  log('#outputs ' .. #(focused.outputs))
  log('focued.geometry.x ' .. focused.geometry.x)
  log('focued.geometry.y ' .. focused.geometry.y)
  log('focued.geometry.width ' .. focused.geometry.width)
  log('focued.geometry.height ' .. focused.geometry.height)
  log('name ' .. screen_name(focused))
end


if true then
  text = ''
  for i, tag in ipairs(root.tags()) do
    text = text .. tag.name .. ': ' .. tag.layout.name .. ' ' .. tag.screen.index .. '\n'
  end
  log(text)
end

for s in screen do
  log('' .. s.index)
end


-- log('instances ' .. ascreen:instances())
-- log('instances ' .. screens[1])
