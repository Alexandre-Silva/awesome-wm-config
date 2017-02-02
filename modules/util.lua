local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local capi = {
  client = client,
  tag = tag,
  screen = screen,
  button = button,
  mouse = mouse,
  root = root,
  timer = timer
}

-- some of the routines are inspired by Shifty (https://github.com/bioe007/awesome-shifty.git)
local util = {}

-----
util.taglist = {}
util.taglist.taglist = {}

function util.taglist.set_taglist(taglist)
  util.taglist.taglist = taglist
end

-----
util.client = {}

function util.client.rel_send(rel_idx)
  local client = capi.client.focus
  if client then
    local scr = capi.client.focus.screen or capi.mouse.screen
    local sel = awful.tag.selected(scr)
    local sel_idx = awful.tag.getidx(sel)
    local tags = awful.tag.gettags(scr)
    local target = awful.util.cycle(#tags, sel_idx + rel_idx)
    client.focus:move_to_tag(target)
    tags[target]:view_only()
  end
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

return util
