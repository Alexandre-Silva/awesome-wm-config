local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")

-- some of the routines are inspired by Shifty (https://github.com/bioe007/awesome-shifty.git)
local util = {}

-----
util.taglist = {}
util.taglist.taglist = {}


--range_mod: returns the module of 'v' offset inside interval [a, b]
function util.range_mod(v, a, b)
  return ((v - a) % ((b + 1) - a)) + a
end

function util.taglist.set_taglist(taglist)
  util.taglist.taglist = taglist
end

--table_jerge: merges two table's items into a third table (for repeated key's t2's value is copied)
--@param name: name of the tag
--@param props: table of properties (screen, index, etc.)
function util.table_join(t1, t2)
  local t3 = awful.util.table.clone(t1)
  for k,v in pairs(t2) do
    if type(v) == "table" then
      if type(t1[k] or false) == "table" then
        t3[k] = table_join(t1[k] or {}, t2[k] or {})
      else
        t3[k] = v
      end
    else
      t3[k] = v
    end
  end
  return t3
end

--tag_names: returns a list of all the tag names. Or, if a screen is provided, its tag names.
--@param screen: A optional screen to returns its tags names
function util.tag_names(screen)
  local tags = {}
  if screen then
    tags = screen.tags
  else
    tags = root.tags()
  end

  local names = {}
  for _, t in ipairs(tags) do
    table.insert(names, t.name)
  end

  return names
end

return util
