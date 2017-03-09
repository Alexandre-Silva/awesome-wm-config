-- Imports {{{
local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local util = require("util")

local config = require("custom.config")

require("awful.autofocus")

local awesome = awesome
local root = root
local mouse = mouse
local screen = screen
local tag = tag
local client = client
-- }}}


local func = {}

-- Prompts {{{

-- prompt_yes_no: Creates a yes/no question and returns true if user enters yes, y, etc.
-- @param prompt: Text to show the user.
-- @param callback: Fuction which accepts single boolean param equal.
-- This param is True if use enter yes or variant, False otherwise.
function func.prompt_yes_no (prompt, callback)
  awful.prompt.run {
    prompt       = prompt ..  " (type 'yes' or 'y' to confirm): ",
    textbox      = awful.screen.focused().mypromptbox.widget,
    exe_callback = function (t) callback(string.lower(t) == 'yes' or string.lower(t) == 'y') end,
    completion_callback =
    function (t, p, n) return awful.completion.generic(t, p, n, {'no', 'No', 'yes', 'Yes'}) end,
  }
end

function func.prompt_run ()
  awful.prompt.run {
    prompt       = "Run: ",
    textbox      = awful.screen.focused().mypromptbox.widget,
    exe_callback = awful.spawn,
    history_path = awful.util.get_cache_dir() .. "/history",
    completion_callback = awful.completion.shell,
  }
end

function func.prompt_run_lua ()
  awful.prompt.run {
    prompt       = "Run Lua code: ",
    textbox      = awful.screen.focused().mypromptbox.widget,
    exe_callback = awful.util.eval,
    history_path = awful.util.get_cache_dir() .. "/history_eval"
  }
end

function func.app_finder ()
  awful.util.spawn("xfce4-appfinder")
end
-- }}}
-- System {{{
function func.system_lock ()
  awful.util.spawn("xscreensaver-command -l")
end

function func.system_suspend ()
  awful.util.spawn("systemctl suspend")
end

function func.system_hibernate ()
  func.prompt_yes_no(
    "Hibernate ?",
    function (yes)
      if yes then awful.util.spawn("systemctl hibernate") end
  end)
end

function func.system_hybrid_sleep ()
  func.prompt_yes_no(
    "Hybrid Sleep ?",
    function (yes)
      if yes then awful.util.spawn("systemctl hybrid-sleep") end
  end)
end

function func.system_reboot ()
  func.prompt_yes_no(
    "Reboot ?",
    function (yes)
      if yes then
        awesome.emit_signal("exit", nil)
        awful.util.spawn("systemctl reboot")
      end
  end)
end

function func.system_power_off ()
  func.prompt_yes_no(
    "Power Off ?",
    function (yes)
      if yes then
        awesome.emit_signal("exit", nil)
        awful.util.spawn("systemctl poweroff")
      end
  end)
end
-- }}}
-- Client {{{
function func.client_focus_next ()
  awful.client.focus.byidx(1)
  if client.focus then client.focus:raise() end
end

function func.client_focus_prev ()
  awful.client.focus.byidx(-1)
  if client.focus then client.focus:raise() end
end

func.client_focus_urgent = awful.client.urgent.jumpto

function func.client_swap_next () awful.client.swap.byidx(  1) end
function func.client_swap_prev () awful.client.swap.byidx( -1) end

--client_move_rel: moves the client to the tag with a certain relative index
--@param rel_idx: The relative index of the target tag to the current one
--@param c: the client to move. If nil defaults to focused client
function func.client_move_rel(rel_idx, c)
  c = c or client.focus

  if c then
    local tgt_idx = c.first_tag.index + rel_idx
    local tgt_tag = c.screen.tags[tgt_idx]
    c:move_to_tag(tgt_tag)
    tgt_tag:view_only()
  end
end

function func.client_move_next () func.client_move_rel(1) end
function func.client_move_prev () func.client_move_rel(-1) end

function func.client_move_to_tag ()
  local keywords = util.tag_names()

  awful.prompt.run {
    prompt       = "Move client to tag: ",
    textbox      = awful.screen.focused().mypromptbox.widget,
    completion_callback = function (t, p, n) return awful.completion.generic(t, p, n, keywords) end,
    exe_callback = function (text)
      local c = client.focus
      tag = func.tag_name2tag(text)

      if tag and c then
        c:move_to_tag(tag)
      end
    end,
  }
end

function func.client_movetoggle_tag (c)
  c = c or client.focus

  local keywords = util.tag_names()

  if c then
    awful.prompt.run {
      prompt       = "Move client to tag: ",
      textbox      = awful.screen.focused().mypromptbox.widget,
      completion_callback = function (t, p, n) return awful.completion.generic(t, p, n, keywords) end,
      exe_callback = function (text)
        local t = func.tag_name2tag(text)
        if t then
          c:toggle_tag(t)
        end
      end,
    }
  end
end

function func.client_toggle_titlebar ()
  awful.titlebar.toggle(client.focus)
end

function func.client_raise (c)
  c:raise()
end

function func.client_fullscreen (c)
  c.fullscreen = not c.fullscreen
end

function func.client_maximize_horizontal (c)
  c.maximized_horizontal = not c.maximized_horizontal
end

function func.client_maximize_vertical (c)
  c.maximized_vertical = not c.maximized_vertical
end

function func.client_maximize (c)
  func.client_maximize_horizontal(c)
  func.client_maximize_vertical(c)
end

function func.client_minimize (c)
  c.minimized = not c.minimized
end

-- function func.client_manage_tag (c, startup)
-- end

-- closures for client_status
-- client_status[client] = {sidelined = <boolean>, geometry= <client geometry>}
local client_status = {}

-- Toggles the sidelining of a given client to a certain geometry.
-- @param c: The client to toggle the sidelining
-- @param geo_transform: The indended geometry transformation function
function func.client_sideline (c, geo_transform)
  c = c or client.focus
  local scr = awful.screen.focused()
  local workarea = scr.workarea

  if client_status[c] == nil then
    client_status[c] = {sidelined=false, geometry=nil}
  end

  if client_status[c].sidelined then
    if client_status[c].geometry then
      c:geometry(client_status[c].geometry)
    end
  else
    client_status[c].geometry = c:geometry()
    geo_transform(workarea)
    c:geometry(workarea)
  end

  client_status[c].sidelined = not client_status[c].sidelined
end

function func.client_sideline_left (c)
  func.client_sideline(
    c,
    function(workarea)
      workarea.width = math.floor(workarea.width/2)
  end)
end

function func.client_sideline_right (c)
  func.client_sideline(
    c,
    function(workarea)
      workarea.x = workarea.x + math.floor(workarea.width/2)
      workarea.width = math.floor(workarea.width/2)
  end)
end

function func.client_sideline_top (c)
  func.client_sideline(
    c,
    function(workarea)
      workarea.height = math.floor(workarea.height/2)
  end)
end

function func.client_sideline_bottom (c)
  func.client_sideline(
    c,
    function(workarea)
      workarea.y = workarea.y + math.floor(workarea.height/2)
      workarea.height = math.floor(workarea.height/2)
  end)
end

function func.client_sideline_extend_left (c, by)
  local cg = c:geometry()
  if by then
    cg.x = cg.x - by
    cg.width = cg.width + by
  else -- use heuristics
    local delta = math.floor(cg.x/7)
    if delta ~= 0 then
      cg.x = cg.x - delta
      cg.width = cg.width + delta
    end
  end
  c:geometry(cg)
end

function func.client_sideline_extend_right (c, by)
  local cg = c:geometry()
  if by then
    cg.width = cg.width + by
  else
    local workarea = screen[mouse.screen].workarea
    local rmargin = math.max( (workarea.x + workarea.width - cg.x - cg.width), 0)
    local delta = math.floor(rmargin/7)
    if delta ~= 0 then
      cg.width = cg.width + delta
    end
  end
  c:geometry(cg)
end

function func.client_sideline_extend_top (c, by)
  local cg = c:geometry()
  if by then
    cg.y = cg.y - by
    cg.height = cg.height + by
  else
    local delta = math.floor(cg.y/7)
    if delta ~= 0 then
      cg.y = cg.y - delta
      cg.height = cg.height + delta
    end
  end
  c:geometry(cg)
end

function func.client_sideline_extend_bottom (c, by)
  local cg = c:geometry()
  if by then
    cg.height = cg.height + by
  else
    local workarea = screen[mouse.screen].workarea
    local bmargin = math.max( (workarea.y + workarea.height - cg.y - cg.height), 0)
    local delta = math.floor(bmargin/7)
    if delta ~= 0 then
      cg.height = cg.height + delta
    end
  end
  c:geometry(cg)
end

function func.client_sideline_shrink_left (c, by)
  local cg = c:geometry()
  local min = config.property.minimal_client_width
  if by then
    cg.width = math.max(cg.width - by, min)
  else
    local delta = math.floor(cg.width/11)
    if delta ~= 0 and cg.width > min then
      cg.width = cg.width - delta
    end
  end
  c:geometry(cg)
end

function func.client_sideline_shrink_right (c, by)
  local cg = c:geometry()
  local min = config.property.minimal_client_width
  if by then
    local t = cg.x + cg.width
    cg.width = math.max(cg.width - by, min)
    cg.x = t - cg.width
  else
    local delta = math.floor(cg.width/11)
    if delta ~= 0 and cg.width > min then
      cg.x = cg.x + delta
      cg.width = cg.width - delta
    end
  end
  c:geometry(cg)
end

function func.client_sideline_shrink_top (c, by)
  local cg = c:geometry()
  local min = config.property.minimal_client_height
  if by then
    cg.height = math.max(cg.height - by, min)
  else
    local delta = math.floor(cg.height/11)
    if delta ~= 0 and cg.height > min then
      cg.height = cg.height - delta
    end
  end
  c:geometry(cg)
end

function func.client_sideline_shrink_bottom (c, by)
  local cg = c:geometry()
  local min = config.property.minimal_client_height
  if by then
    local t = cg.y + cg.width
    cg.height = math.max(cg.height - by, min)
    cg.y = t - cg.height
  else
    local delta = math.floor(cg.height/11)
    if delta ~= 0 and cg.height > min then
      cg.y = cg.y + delta
      cg.height = cg.height - delta
    end
  end
  c:geometry(cg)
end

function func.client_opaque_less (c)
  local opacity = c.opacity - 0.1
  if opacity and opacity >= config.property.min_opacity then
    c.opacity = opacity
  end
end

function func.client_opaque_more (c)
  local opacity = c.opacity + 0.1
  if opacity and opacity <= config.property.max_opacity then
    c.opacity = opacity
  end
end

function func.client_opaque_off (c)
  awful.spawn.spawn.with_shell("pkill " .. config.compmgr)
end

function func.client_opaque_on (c)
  awful.spawn.with_shell(config.compmgr.. " " .. config.compmgr_args)
end

function func.client_swap_with_master (c)
  c:swap(awful.client.getmaster())
end

function func.client_toggle_top (c)
  c.ontop = not c.ontop
end

function func.client_toggle_sticky (c)
  c.sticky = not c.sticky
end

function func.client_kill (c)
  c:kill()
end

do
  local instance = nil
  func.client_action_menu = function (c)
    local clear_instance = function ()
      if instance then
        instance:hide()
        instance = nil
      end
    end
    if instance and instance.wibox.visible then
      clear_instance()
      return
    end
    c = c or client.focus
    instance = awful.menu({
        theme = {
          width = 200,
        },
        items = {
          {"&cancel",                   function () clear_instance() end},
          {"=== task action menu ===",  function () clear_instance() end},

          {"--- status ---",   function () clear_instance(); end},
          {"&raise",           function () clear_instance(); func.client_raise(c) end},
          {"&top",             function () clear_instance(); func.client_toggle_top(c) end},
          {"&sticky",          function () clear_instance(); func.client_toggle_sticky(c) end},
          {"&kill",            function () clear_instance(); func.client_kill(c) end},
          {"toggle title&bar", function () clear_instance(); func.client_toggle_titlebar(c) end},

          {"--- focus ---",    function () clear_instance(); end},
          {"&next client",     function () clear_instance(); func.client_focus_next(c) end},
          {"&prev client",     function () clear_instance(); func.client_focus_prev(c) end},
          {"&urgent",          function () clear_instance(); func.client_focus_urgent(c) end},

          {"--- tag ---",      function () clear_instance(); end},
          {"move to next tag", function () clear_instance(); func.client_move_next(c) end},
          {"move to prev tag", function () clear_instance(); func.client_move_prev(c) end},
          {"move to ta&g",     function () clear_instance(); func.client_move_to_tag(c) end},
          {"togg&le tag",      function () clear_instance(); func.client_movetoggle_tag(c) end},

          {"--- geometry ---", function () clear_instance(); end},
          {"&fullscreen",      function () clear_instance(); func.client_fullscreen(c) end},
          {"m&aximize",        function () clear_instance(); func.client_maximize(c) end},
          {"maximize h&orizontal", function () clear_instance(); func.client_maximize_horizontal(c) end},
          {"maximize &vertical", function () clear_instance(); func.client_maximize_vertical(c) end},
          {"m&inimize",        function () clear_instance(); func.client_minimize(c) end},
          {"move to left",     function () clear_instance(); func.client_sideline_left(c) end},
          {"move to right",    function () clear_instance(); func.client_sideline_right(c) end},
          {"move to top",      function () clear_instance(); func.client_sideline_top(c) end},
          {"move to bottom",   function () clear_instance(); func.client_sideline_bottom(c) end},
          {"extend left",      function () clear_instance(); func.client_sideline_extend_left(c) end},
          {"extend right",     function () clear_instance(); func.client_sideline_extend_right(c) end},
          {"extend top",       function () clear_instance(); func.client_sideline_extend_top(c) end},
          {"extend bottom",    function () clear_instance(); func.client_sideline_extend_bottom(c) end},
          {"shrink left",      function () clear_instance(); func.client_sideline_shrink_left(c) end},
          {"shrink right",     function () clear_instance(); func.client_sideline_shrink_right(c) end},
          {"shrink top",       function () clear_instance(); func.client_sideline_shrink_top(c) end},
          {"shrink bottom",    function () clear_instance(); func.client_sideline_shrink_bottom(c) end},

          {"--- opacity ---",  function () clear_instance(); end},
          {"&less opaque",     function () clear_instance(); func.client_opaque_less(c) end},
          {"&more opaque",     function () clear_instance(); func.client_opaque_more(c) end},
          {"opacity off",      function () clear_instance(); func.client_opaque_off(c) end},
          {"opacity on",       function () clear_instance(); func.client_opaque_on(c) end},

          {"--- ordering ---", function () clear_instance(); end},
          {"swap with master", function () clear_instance(); func.client_swap_with_master(c) end},
          {"swap with next",   function () clear_instance(); func.client_swap_next(c) end},
          {"swap with prev",   function () clear_instance(); func.client_swap_prev(c) end},
        }
    })
    instance:toggle({keygrabber=true})
  end
end
-- }}}
-- Tag  {{{
--tag_rel_move: Moves the tags position relationaly to its current position
--@param rel_idx: the relative target position. -1 swaps postion with the previous tag, 1 with the next.
--@param t: the tag to move, or if nil the focused tag
function func.tag_rel_move(rel_idx, t)
  t = t or awful.screen.focused().selected_tag
  if t then
    t.index = t.index + rel_idx
    t:view_only()
  end
end

function func.tag_move_forward () func.tag_rel_move( 1) end
function func.tag_move_backward () func.tag_rel_move(-1) end

--name2tags: matches string 'name' to tag objects
--@param name: tag name to find
--@param scr: screen to look for tags on
--@return table of tag objects or nil
function func.tag_name2tags(name, scr)
  local ret = {}
  local tags
  if scr then
    tags = scr.tags
  else
    tags = root.tags()
  end

  for _, t in ipairs(tags) do
    if name == t.name then
      table.insert(ret, t)
    end
  end
  if #ret > 0 then return ret end
end

function func.tag_name2tag(name, scr, idx)
  local ts = func.tag_name2tags(name, scr)
  if ts then return ts[idx or 1] end
end

--debug -- used to probe internal structures of taglist widget
local function debug_taglist(scr, t)
  do
    local key = ""
    for k, _ in pairs(util.taglist.taglist[scr].widgets[t.index].widget.widgets[2].widget) do
      key = key .. "\n" .. k
    end
    naughty.notify(
      {
        title=scr,
        text=key,
        timeout=20,
      }
    )
  end
end

--rename
--@param t: tag object to be renamed (Defaults to focused tag)
--@param callback: function called after a promp asking for a name is done
function func.tag_rename(t, callback)
  t = t or awful.screen.focused().selected_tag
  local theme = beautiful.get()

  if not t then return end

  local bg
  local fg
  if t.screen.selected_tag == t then
    bg = theme.bg_focus or '#535d6c'
    fg = theme.fg_urgent or '#ffffff'
  else
    bg = theme.bg_normal or '#222222'
    fg = theme.fg_urgent or '#ffffff'
  end

  awful.prompt.run({
      fg_cursor = fg,
      bg_cursor = bg,
      ul_cursor = "single",
      prompt = "(Re)Name tag to: ",
      text = t.name,
      selectall = true,
      textbox = awful.screen.focused().mypromptbox.widget,

      exe_callback = function(new_name)
        if new_name and #new_name > 0 then
          t.name = new_name
        end
      end,

      done_callback = function ()
        if callback then
          callback()
        end
      end,
  })
end

--add: add a tag
--@param name: name of the tag (Optional)
--@param props: properties for the new tag (screen, index, etc.) (Optional)
function func.tag_add(name, props)
  props = util.table_join({
      screen = awful.screen.focused(),
      index = 1,
      layout = config.property.layout,
      mwfact = config.property.mwfact,
      nmaster = config.property.nmaster,
      ncol = config.property.ncol,
                          },
    props)

  local t = awful.tag.add(name or "", props)
  if t then
    t:view_only()
  end

  -- if add the tag interactively
  if not name then
    local cb = function ()
      if not t.name or #t.name == 0 then
        t:delete()
      end
    end

    func.tag_rename(t, cb)
  end

  return t
end

--tag_add_rel: add a tag in the focused screen in the position of the currently focused tag
--@param name: name of the tag (Optional)
--@param red_idx: Relative index, -1 (or lower) tag is placed beind focused tag. 0 where the current tag is. 1 or higher, after the selected tag
--@param props: properties for the new tag (screen, index, etc.) (Optional)
function func.tag_add_rel (name, rel_idx, props)
  local idx = 1
  local t = awful.screen.focused().selected_tag
  if t then idx = t.index + rel_idx end
  props = util.table_join(props or {}, {index = idx})
  return func.tag_add(name, props)
end

function func.tag_add_after  () return func.tag_add_rel(nil, 1) end
function func.tag_add_before () return func.tag_add_rel(nil, 0) end

function func.tag_delete ()
  local t = awful.screen.focused().selected_tag
  if t then
    t:delete()
  end
end

func.tag_view_prev = awful.tag.viewprev
func.tag_view_next = awful.tag.viewnext

func.tag_last = awful.tag.history.restore

function func.tag_goto ()
  local keywords = util.tag_names(awful.screen.focused())
  awful.prompt.run {
    prompt       = "Goto tag: ",
    textbox      = awful.screen.focused().mypromptbox.widget,
    completion_callback = function (t, p, n) return awful.completion.generic(t, p, n, keywords) end,
    exe_callback = function (t)
      func.tag_name2tag(t):view_only()
    end,
  }
end

function func.tag_move_screen (rel_idx)
  local t = awful.screen.focused().selected_tag

  if t then
    local tgt_idx = (t.screen.index + rel_idx - 1) % screen:count() + 1
    local s_tgt = screen[tgt_idx]
    t.screen = s_tgt
    t:view_only()
    awful.screen.focus(s_tgt)
  end
end

function func.tag_move_screen_next () func.tag_move_screen( 1) end
function func.tag_move_screen_prev () func.tag_move_screen(-1) end

do
  local instance = nil
  function func.tag_action_menu (t)
    local clear_instance = function ()
      if instance then
        instance:hide()
        instance = nil
      end
    end
    if instance and instance.wibox.visible then
      clear_instance()
      return
    end
    t = t or tag.selected()
    if t then
      instance = awful.menu({
          theme = {
            width = 200,
          },
          items = {
            {"&cancel",                   function () clear_instance() end},
            {"=== tag action menu ===",   function () clear_instance() end},

            {"--- dynamic tagging ---",   function () clear_instance(); end},
            {"add tag &after this one",   function () clear_instance(); func.tag_add_after(t) end},
            {"add tag &before this one",  function () clear_instance(); func.tag_add_before(t) end},
            {"&delete this tag if empty", function () clear_instance(); func.tag_delete(t) end},
            {"&rename this tag",          function () clear_instance(); func.tag_rename(t) end},

            {"--- focus ---",             function () clear_instance(); end},
            {"&goto tag",                 function () clear_instance(); func.tag_goto(t) end},
            {"view &previous tag",        function () clear_instance(); func.tag_view_prev(t) end},
            {"view &next tag",            function () clear_instance(); func.tag_view_next(t) end},
            {"view &last tag",            function () clear_instance(); func.tag_last(t) end},

            {"--- ordering ---",          function () clear_instance(); end},
            {"move tag &forward",         function () clear_instance(); func.tag_move_forward() end},
            {"move tag &backward",        function () clear_instance(); func.tag_move_backward() end},

            {"--- screen ---",            function () clear_instance(); end},
            {"move tag to pre&vious window", function () clear_instance() func.tag_move_screen_prev() end},
            {"move tag to ne&xt window",  function () clear_instance() func.tag_move_screen_next() end},
          }
      })
      instance:toggle({keygrabber=true})
    end
  end
end

-- }}}
-- clients on tags {{{
do
  local instance = nil
  function   func.clients_on_tag ()
    local clear_instance = function ()
      if instance then
        instance:hide()
        instance = nil
      end
    end
    if instance and instance.wibox.visible then
      clear_instance()
      return
    end
    local clients = {
      items = {},
      theme = { width = 400 },
    }
    local next = next
    local t = tag.selected()
    if t then
      for _, c in pairs(t:clients()) do
        if c.focusable and c.pid ~= 0 then
          table.insert(clients.items, {
                         c.name .. " ~" .. tostring(c.pid) or "",
                         function ()
                           clear_instance()
                           client.focus = c
                           c:raise()
                         end,
                         c.icon
          })
        end
      end
      if next(clients.items) ~= nil then
        instance = awful.menu(clients)
        instance:toggle({keygrabber=true})
      end
    end
  end
end

function func.clients_on_tag_prompt ()
  local clients = {}
  local t = tag.selected()
  if t then
    local keywords = {}
    for _, c in pairs(t:clients()) do
      if c.focusable and c.pid ~= 0 then
        local k = c.name .. " ~" .. tostring(c.pid) or ""
        if k ~= "" then
          clients[k] = c
          table.insert(keywords, k)
        end
      end
    end

    awful.prompt.run {
      prompt       = "Focus on client on current tag: ",
      textbox      = awful.screen.focused().mypromptbox.widget,
      completion_callback = function (t, p, n) return awful.completion.generic(t, p, n, keywords) end,
      exe_callback = function (t)
        local c = clients[t]
        if c then
          client.focus = c
          c:raise()
        end
      end,
    }
  end
end

do
  local instance = nil
  function   func.all_clients ()
    local clear_instance = function ()
      if instance then
        instance:hide()
        instance = nil
      end
    end
    if instance and instance.wibox.visible then
      clear_instance()
      return
    end
    local clients = {
      items = {},
      theme = { width = 400},
    }
    local next = next
    for _, c in pairs(client.get()) do
      if c.focusable and c.pid ~= 0 then
        table.insert(clients.items, {
                       c.name .. " ~" .. tostring(c.pid) or "",
                       function ()
                         local t = c:tags()
                         if t then
                           t[1]:view_only()
                         end
                         clear_instance()
                         client.focus = c
                         c:raise()
                       end,
                       c.icon
        })
      end
    end
    if next(clients.items) ~= nil then
      instance = awful.menu(clients)
      instance:toggle({keygrabber=true})
    end
  end
end

function func.all_clients_prompt ()
  local clients = {}
  local next = next
  local keywords = {}
  for _, c in pairs(client.get()) do
    if c.focusable and c.pid ~= 0 then
      local k = c.name .. " ~" .. tostring(c.pid) or ""
      if k ~= "" then
        clients[k] = c
        table.insert(keywords, k)
      end
    end
  end
  if next(clients) ~= nil then
    awful.prompt.run {
      prompt       = "Focus on client from global list: ",
      textbox      = awful.screen.focused().mypromptbox.widget,
      completion_callback = function (t, p, n) return awful.completion.generic(t, p, n, keywords) end,
      exe_callback = function (t)
        local c = clients[t]
        if c then
          local t = c:tags()
          if t then
            t[1]:view_only()
          end
          client.focus = c
          c:raise()
        end
      end,
    }
  end
end

do
  local instance = nil
  function   func.systeminfo ()
    if instance then
      naughty.destroy(instance)
      instance = nil
      return
    end
    local info = "Version: " .. awesome.version
    info = info ..  "\n" .. "Release: " .. awesome.release
    info = info ..  "\n" .. "Config: " .. awesome.conffile
    info = info ..  "\n" .. "Config Version: " .. config.version
    info = info ..  "\n" .. "Config Help: " .. config.help_url
    if awesome.composite_manager_running then
      info = info .. "\n" .. "<span fgcolor='red'>a composite manager is running</span>"
    end
    local uname = awful.util.pread("uname -a")
    if string.gsub(uname, "%s", "") ~= "" then
      info = info .. "\n" .. "OS: " .. string.gsub(uname, "%s+$", "")
    end
    -- remove color code from screenfetch output
    local archey = awful.util.pread("screenfetch -N")
    if string.gsub(archey, "%s", "") ~= "" then
      info = info .. "\n\n<span face='monospace'>" .. archey .. "</span>"
    end
    info = string.gsub(info, "(%u[%a ]*:)%f[ ]", "<span color='red'>%1</span>")
    local tmp = awesome.composite_manager_running
    awesome.composite_manager_running = false
    instance = naughty.notify({
        preset = naughty.config.presets.normal,
        title="awesome info",
        text=info,
        timeout = 10,
        screen = mouse.screen,
    })
    awesome.composite_manager_running = tmp
  end
end

do
  local instance = nil
  function   func.help ()
    if instance then
      naughty.destroy(instance)
      instance = nil
      return
    end
    local text = ""
    text = text .. "You are running awesome <span fgcolor='red'>" .. awesome.version .. "</span> (<span fgcolor='red'>" .. awesome.release .. "</span>)"
    text = text .. "\n" .. "with config version <span fgcolor='red'>" .. config.version .. "</span>"
    text = text .. "\n\n" .. "help can be found at the URL: <u>" .. config.help_url .. "</u>"
    text = text .. "\n\n\n\n" .. "opening in <b>" .. config.browser.primary .. "</b>..."
    instance = naughty.notify({
        preset = naughty.config.presets.normal,
        title="help about configuration",
        text=text,
        timeout = 20,
        screen = mouse.screen,
    })
    awful.spawn.with_shell(config.browser.primary .. " '" .. config.help_url .. "'")
  end
end

-- }}}

return func
