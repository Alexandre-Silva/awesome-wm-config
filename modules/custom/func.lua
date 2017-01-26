-- Imports {{{
local awful = require("awful")
local naughty = require("naughty")
local util = require("util")

local default = require("custom.default")
local widgets = require("custom.widgets")
local config = require("custom.config")
-- }}}


local func = {}

-- Prompts {{{

-- prompt_yes_no: Creates a yes/no question and returns true if user enters yes, y, etc.
-- @param prompt: Text to show the user.
-- @param callback: Fuction which accepts single boolean param equal.
-- This param is True if use enter yes or variant, False otherwise.
func.prompt_yes_no = function(prompt, callback)
  awful.screen.focused().mypromptbox:run(
    awful.prompt.run({prompt = prompt .. " (type 'yes' or 'y' to confirm): "},
      function (t)
        callback(string.lower(t) == 'yes' or string.lower(t) == 'y') end,
      function (t, p, n)
        return awful.completion.generic(t, p, n, {'no', 'No', 'yes', 'Yes'}) end))
end

func.prompt_run = function ()
  awful.screen.focused().mypromptbox:run(
    {prompt = "Run: "},
    awful.spawn,
    awful.completion.shell,
    awful.util.getdir("cache") .. "/history")
end

func.prompt_run_lua = function ()
  awful.prompt.run(
    {prompt = "Run Lua code: "},
    widgets.promptbox[mouse.screen].widget,
    awful.util.eval,
    nil,
    awful.util.getdir("cache") .. "/history_lua")
end

func.app_finder = function ()
  awful.util.spawn("xfce4-appfinder")
end
-- }}}
-- System {{{
func.system_lock = function ()
  awful.util.spawn("xscreensaver-command -l")
end

func.system_suspend = function ()
  awful.util.spawn("systemctl suspend")
end

func.system_hibernate = function ()
  func.prompt_yes_no(
    "Hibernate ?",
    function (yes)
      if yes then awful.util.spawn("systemctl hibernate") end
  end)
end

func.system_hybrid_sleep = function ()
  func.prompt_yes_no(
    "Hybrid Sleep ?",
    function (yes)
      if yes then awful.util.spawn("systemctl hybrid-sleep") end
  end)
end

func.system_reboot = function ()
  func.prompt_yes_no(
    "Reboot ?",
    function (yes)
      if yes then
        awesome.emit_signal("exit", nil)
        awful.util.spawn("systemctl reboot")
      end
  end)
end

func.system_power_off = function ()
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
func.client_focus_next = function ()
  awful.client.focus.byidx(1)
  if client.focus then client.focus:raise() end
end

func.client_focus_prev = function ()
  awful.client.focus.byidx(-1)
  if client.focus then client.focus:raise() end
end

func.client_focus_urgent = awful.client.urgent.jumpto

func.client_swap_next = function () awful.client.swap.byidx(  1) end
func.client_swap_prev = function () awful.client.swap.byidx( -1) end
func.client_move_next = function () util.client.rel_send(1) end
func.client_move_prev = function () util.client.rel_send(-1) end

func.client_move_to_tag = function ()
  local keywords = {}
  local scr = mouse.screen
  for _, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
    table.insert(keywords, t.name)
  end
  awful.prompt.run({prompt = "Move client to tag: "},
    widgets.promptbox[scr].widget,
    function (t)
      local tag = util.tag.name2tag(t)
      if tag then
        awful.client.movetotag(tag)
      end
    end,
    function (t, p, n)
      return awful.completion.generic(t, p, n, keywords)
    end,
    nil)
end

func.client_toggle_tag = function (c)
  local keywords = {}
  local scr = mouse.screen
  for _, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
    table.insert(keywords, t.name)
  end
  local c = c or client.focus
  awful.prompt.run({prompt = "Toggle tag for " .. c.name .. ": "},
    widgets.promptbox[scr].widget,
    function (t)
      local tag = util.tag.name2tag(t)
      if tag then
        awful.client.toggletag(tag)
      end
    end,
    function (t, p, n)
      return awful.completion.generic(t, p, n, keywords)
    end,
    nil)
end

func.client_toggle_titlebar = function ()
  awful.titlebar.toggle(client.focus)
end

func.client_raise = function (c)
  c:raise()
end

func.client_fullscreen = function (c)
  c.fullscreen = not c.fullscreen
end

func.client_maximize_horizontal = function (c)
  c.maximized_horizontal = not c.maximized_horizontal
end

func.client_maximize_vertical = function (c)
  c.maximized_vertical = not c.maximized_vertical
end

func.client_maximize = function (c)
  func.client_maximize_horizontal(c)
  func.client_maximize_vertical(c)
end

func.client_minimize = function (c)
  c.minimized = not c.minimized
end

func.client_manage_tag = function (c, startup)
end

-- closures for client_status
-- client_status[client] = {sidelined = <boolean>, geometry= <client geometry>}
local client_status = {}

func.client_sideline_left = function (c)
  local scr = screen[mouse.screen]
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
    workarea.width = math.floor(workarea.width/2)
    c:geometry(workarea)
  end
  client_status[c].sidelined = not client_status[c].sidelined
end

func.client_sideline_right = function (c)
  local scr = screen[mouse.screen]
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
    workarea.x = workarea.x + math.floor(workarea.width/2)
    workarea.width = math.floor(workarea.width/2)
    c:geometry(workarea)
  end
  client_status[c].sidelined = not client_status[c].sidelined
end

func.client_sideline_top = function (c)
  local scr = screen[mouse.screen]
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
    workarea.height = math.floor(workarea.height/2)
    c:geometry(workarea)
  end
  client_status[c].sidelined = not client_status[c].sidelined
end

func.client_sideline_bottom = function (c)
  local scr = screen[mouse.screen]
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
    workarea.y = workarea.y + math.floor(workarea.height/2)
    workarea.height = math.floor(workarea.height/2)
    c:geometry(workarea)
  end
  client_status[c].sidelined = not client_status[c].sidelined
end

func.client_sideline_extend_left = function (c, by)
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

func.client_sideline_extend_right = function (c, by)
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

func.client_sideline_extend_top = function (c, by)
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

func.client_sideline_extend_bottom = function (c, by)
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

func.client_sideline_shrink_left = function (c, by)
  local cg = c:geometry()
  local min = default.property.minimal_client_width
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

func.client_sideline_shrink_right = function (c, by)
  local cg = c:geometry()
  local min = default.property.minimal_client_width
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

func.client_sideline_shrink_top = function (c, by)
  local cg = c:geometry()
  local min = default.property.minimal_client_height
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

func.client_sideline_shrink_bottom = function (c, by)
  local cg = c:geometry()
  local min = default.property.minimal_client_height
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

func.client_opaque_less = function (c)
  local opacity = c.opacity - 0.1
  if opacity and opacity >= default.property.min_opacity then
    c.opacity = opacity
  end
end

func.client_opaque_more = function (c)
  local opacity = c.opacity + 0.1
  if opacity and opacity <= default.property.max_opacity then
    c.opacity = opacity
  end
end

func.client_opaque_off = function (c)
  awful.util.spawn_with_shell("pkill " .. default.compmgr)
end

func.client_opaque_on = function (c)
  awful.util.spawn_with_shell(default.compmgr.. " " .. default.compmgr_args)
end

func.client_swap_with_master = function (c)
  c:swap(awful.client.getmaster())
end

func.client_toggle_top = function (c)
  c.ontop = not c.ontop
end

func.client_toggle_sticky = function (c)
  c.sticky = not c.sticky
end

func.client_kill = function (c)
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
          {"togg&le tag",      function () clear_instance(); func.client_toggle_tag(c) end},

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

func.tag_add_after = function ()
  local scr = mouse.screen
  local sel_idx = awful.tag.getidx()
  local t = util.tag.add(nil,
                         {
                           screen = scr,
                           index = sel_idx and sel_idx+1 or 1,
                           layout = default.property.layout,
                           mwfact = default.property.mwfact,
                           nmaster = default.property.nmaster,
                           ncol = default.property.ncol,
  })
end

func.tag_add_before = function ()
  local scr = mouse.screen
  local sel_idx = awful.tag.getidx()
  local t = util.tag.add(nil,
                         {
                           screen = scr,
                           index = sel_idx and sel_idx or 1,
                           layout = default.property.layout,
                           mwfact = default.property.mwfact,
                           nmaster = default.property.nmaster,
                           ncol = default.property.ncol,
  })
end

func.tag_delete = awful.tag.delete

func.tag_rename = function ()
  local scr = mouse.screen
  local sel = awful.tag.selected(scr)
  util.tag.rename(sel)
end

func.tag_view_prev = awful.tag.viewprev
func.tag_view_next = awful.tag.viewnext

func.tag_last = awful.tag.history.restore

func.tag_goto = function ()
  local keywords = {}
  local scr = mouse.screen
  for _, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
    table.insert(keywords, t.name)
  end
  awful.prompt.run({prompt = "Goto tag: "},
    widgets.promptbox[scr].widget,
    function (t)
      util.tag.name2tag(t):view_only()
    end,
    function (t, p, n)
      return awful.completion.generic(t, p, n, keywords)
  end)
end

func.tag_move_forward = function ()
  util.tag.rel_move(awful.tag.selected(), 1)
end

func.tag_move_backward = function ()
  util.tag.rel_move(awful.tag.selected(), -1)
end

func.tag_move_screen = function (scrdelta)
  local seltag = awful.tag.selected()
  local scrcount = capi.screen.count()
  if seltag then
    local s = awful.tag.getscreen(seltag) + scrdelta
    if s > scrcount then s = 1 elseif s < 1 then s = scrcount end
    awful.tag.setscreen(seltag, s)
    seltag:view_only()
    awful.screen.focus(s)
  end
end

func.tag_move_screen_prev = function ()
  func.tag_move_screen(-1)
end

func.tag_move_screen_next = function ()
  func.tag_move_screen(1)
end

do
  local instance = nil
  func.tag_action_menu = function (t)
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
    t = t or awful.tag.selected()
    if t then
      instance = awful.menu({
          theme = {
            width = 200,
          },
          items = {
            {"&cancel", function () clear_instance() end},
            {"=== tag action menu ===", function () clear_instance() end},

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
  func.clients_on_tag = function ()
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
    local t = awful.tag.selected()
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

func.clients_on_tag_prompt = function ()
  local clients = {}
  local next = next
  local t = awful.tag.selected()
  if t then
    local keywords = {}
    local scr = mouse.screen
    for _, c in pairs(t:clients()) do
      if c.focusable and c.pid ~= 0 then
        local k = c.name .. " ~" .. tostring(c.pid) or ""
        if k ~= "" then
          clients[k] = c
          table.insert(keywords, k)
        end
      end
    end
    if next(clients) ~= nil then
      awful.prompt.run({prompt = "Focus on client on current tag: "},
        widgets.promptbox[scr].widget,
        function (t)
          local c = clients[t]
          if c then
            client.focus = c
            c:raise()
          end
        end,
        function (t, p, n)
          return awful.completion.generic(t, p, n, keywords)
      end)
    end
  end
end

do
  local instance = nil
  func.all_clients = function ()
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

func.all_clients_prompt = function ()
  local clients = {}
  local next = next
  local keywords = {}
  local scr = mouse.screen
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
    awful.prompt.run({prompt = "Focus on client from global list: "},
      widgets.promptbox[scr].widget,
      function (t)
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
      function (t, p, n)
        return awful.completion.generic(t, p, n, keywords)
    end)
  end
end

do
  local instance = nil
  func.systeminfo = function ()
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
  func.help = function ()
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
    awful.util.spawn_with_shell(config.browser.primary .. " '" .. config.help_url .. "'")
  end
end

-- }}}

return func
