local awful = require("awful")
local uniarg = require("uniarg")
local util = require("util")

local widgets = require("custom.widgets")
local func = require("custom.func")
local structure = require("custom.structure")
local config = require("custom.config")


local binds = {}


-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other custom.config.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"
binds.modkey = modkey

-- {{{ Utils
-- Gets the 'index'-esme tag with in the given 'focus'
-- @param index The index of indended tag (starts at 1)
-- @param screen The screen to search for the tag
-- @return The newly created tag
local function get_tag(index, screen)
  local tag
  local tags = awful.tag.gettags(screen)
  if index <= #tags then
    return tags[index]
  else
    return util.tag.add(
      nil,
      {
        screen = screen,
        index = #tags + 1,
    })
  end
end
-- }}}
-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
               awful.button({ }, 1, func.all_clients),
               awful.button({ }, 2, func.tag_action_menu),
               awful.button({ }, 3, function () structure.main_menu:toggle() end),
               awful.button({ }, 4, awful.tag.viewprev),
               awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}
-- {{{ universal arguments
binds.globalkeys = awful.util.table.join(
  awful.key({ modkey }, "u",
    function ()
      uniarg:activate()
      awful.prompt.run(
        {prompt = "Universal Argument: ", text='' .. uniarg.arg, selectall=true},
        widgets.promptbox[mouse.screen].widget,
        function (t)
          uniarg.persistent = false
          local n = t:match("%d+")
          if n then
            uniarg:set(n)
            uniarg:update_textbox()
            if uniarg.arg>1 then
              return
            end
          end
          uniarg:deactivate()
      end)
  end),

  -- persistent universal arguments
  awful.key({ modkey, "Shift" }, "u",
    function ()
      uniarg:activate()
      awful.prompt.run(
        {prompt = "Persistent Universal Argument: ", text='' .. uniarg.arg, selectall=true},
        widgets.promptbox[mouse.screen].widget,
        function (t)
          uniarg.persistent = true
          local n = t:match("%d+")
          if n then
            uniarg:set(n)
          end
          uniarg:update_textbox()
      end)
  end)
)
-- }}}
-- {{{ window management
binds.globalkeys = awful.util.table.join(
  binds.globalkeys,

  --- restart/quit/info
  awful.key({ modkey, "Control" }, "r", awesome.restart),
  awful.key({ modkey, "Shift"   }, "q", awesome.quit),
  awful.key({ modkey            }, "\\", func.systeminfo),
  awful.key({ modkey            }, "F1", func.help),
  awful.key({ "Ctrl", "Shift"   }, "Escape", function () awful.util.spawn(config.system.taskmanager) end),

  --- Layout
  uniarg:key_repeat({ modkey,           }, "space", function () awful.layout.inc(config.layouts,  1) end),
  uniarg:key_repeat({ modkey, "Shift"   }, "space", function () awful.layout.inc(config.layouts, -1) end),

  --- multiple screens/multi-head/RANDR
  uniarg:key_repeat({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
  uniarg:key_repeat({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
  uniarg:key_repeat({ modkey,           }, "o", awful.client.movetoscreen),
  uniarg:key_repeat({ modkey, "Control" }, "o", func.tag_move_screen_next),
  uniarg:key_repeat({ modkey, "Shift", "Control" }, "o", func.tag_move_screen_prev),

  --- misc
  awful.key({modkey}, "F2", function()
      awful.prompt.run(
        {prompt = "Run: "},
        widgets.promptbox[mouse.screen].widget,
        awful.util.spawn, awful.completion.shell,
        awful.util.getdir("cache") .. "/history"
      )
  end),

  awful.key({modkey}, "r", function()
      awful.prompt.run(
        {prompt = "Run: "},
        widgets.promptbox[mouse.screen].widget,
        awful.util.spawn, awful.completion.shell,
        awful.util.getdir("cache") .. "/history"
      )
  end),

  -- awful.key({modkey}, "F3", function()
  --     local config_path = awful.util.getdir("config")
  --     awful.util.spawn_with_shell(config_path .. "/bin/trackpad-toggle.sh")
  -- end),

  awful.key({modkey}, "F4", function()
      awful.prompt.run(
        {prompt = "Run Lua code: "},
        widgets.promptbox[mouse.screen].widget,
        awful.util.eval, nil,
        awful.util.getdir("cache") .. "/history_eval"
      )
  end),

  awful.key({ modkey }, "c", function ()
      awful.util.spawn(config.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua" )
  end),

  awful.key({ modkey, }, ";", function()
      local c = client.focus
      if c then
        func.client_action_menu(c)
      end
  end),

  awful.key({ modkey, "Shift" }, ";", func.tag_action_menu),
  awful.key({ modkey,         }, "'", func.clients_on_tag),
  awful.key({ modkey, "Ctrl"  }, "'", func.clients_on_tag_prompt),
  awful.key({ modkey, "Shift" }, "'", func.all_clients),
  awful.key({ modkey,         }, "x", function() structure.main_menu:toggle({keygrabber=true}) end),
  awful.key({ modkey, "Shift", "Ctrl" }, "'", func.all_clients_prompt),
  uniarg:key_repeat({ modkey,         }, "Return", function () awful.util.spawn(config.terminal) end),
  uniarg:key_repeat({ modkey, "Mod1"  }, "Return",
    function () awful.util.spawn("gksudo " .. config.terminal)
  end),

  --- add/delete/rename
  awful.key({modkey         }, "a", func.tag_add_after),
  awful.key({modkey, "Shift"}, "a", func.tag_add_before),
  awful.key({modkey, "Shift"}, "d", func.tag_delete),
  awful.key({modkey, "Shift"}, "r", func.tag_rename),

  --- view
  uniarg:key_repeat({modkey,}, "p", func.tag_view_prev),
  uniarg:key_repeat({modkey,}, "n", func.tag_view_next),
  awful.key({modkey,}, "z", func.tag_last),
  awful.key({modkey,}, "g", func.tag_goto),

  --- move
  uniarg:key_repeat({modkey, "Control"}, "p", func.tag_move_backward),
  uniarg:key_repeat({modkey, "Control"}, "n", func.tag_move_forward),

  -- }}}
  -- {{{ Client management
  --- change focus
  uniarg:key_repeat({ modkey,           }, "k", func.client_focus_next),
  uniarg:key_repeat({ modkey,           }, "Tab", func.client_focus_next),
  uniarg:key_repeat({ modkey,           }, "j", func.client_focus_prev),
  uniarg:key_repeat({ modkey, "Shift"   }, "Tab", func.client_focus_prev),
  awful.key({ modkey,                   }, "y", func.client_focus_urgent),

  --- swap order/select master
  uniarg:key_repeat({ modkey, "Shift"   }, "j", func.client_swap_prev),
  uniarg:key_repeat({ modkey, "Shift"   }, "k", func.client_swap_next),

  --- move/copy to tag
  uniarg:key_repeat({modkey,    "Shift"}, "n", func.client_move_next),
  uniarg:key_repeat({modkey,    "Shift"}, "p", func.client_move_prev),
  awful.key({modkey,            "Shift"}, "g", func.client_move_to_tag),
  awful.key({modkey, "Control", "Shift"}, "g", func.client_toggle_tag),

  --- change space allocation in tile layout
  awful.key({ modkey,                   }, "=",     function () awful.tag.setmwfact( 0.5) end),
  awful.key({ modkey,                   }, "l",     function () awful.tag.incmwfact( 0.05) end),
  awful.key({ modkey,                   }, "h",     function () awful.tag.incmwfact(-0.05) end),
  uniarg:key_repeat({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster( 1) end),
  uniarg:key_repeat({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster(-1) end),
  uniarg:key_repeat({ modkey, "Control" }, "l",     function () awful.tag.incncol( 1) end),
  uniarg:key_repeat({ modkey, "Control" }, "h",     function () awful.tag.incncol(-1) end),

  --- misc
  awful.key({ modkey, "Shift" }, "`", func.client_toggle_titlebar),

  -- }}}
  -- {{{ app bindings
  --- admin
  awful.key({ modkey,         }, "`", func.system_lock),
  awful.key({ modkey,         }, "Home", func.system_lock),
  awful.key({ modkey,         }, "End", func.system_suspend),
  awful.key({ modkey,  "Mod1" }, "Home", func.system_hibernate),
  awful.key({ modkey,  "Mod1" }, "End", func.system_hybrid_sleep),
  awful.key({ modkey,         }, "Insert", func.system_reboot),
  awful.key({ modkey,         }, "Delete", func.system_power_off),
  awful.key({ modkey,         }, "/", func.app_finder),

  --- everyday
  uniarg:key_repeat({ modkey, "Mod1", }, "l", function () awful.util.spawn(config.system.filemanager) end),
  uniarg:key_repeat({ modkey,         }, "e", function () awful.util.spawn(config.system.filemanager) end),
  uniarg:key_repeat({ modkey,         }, "E", function () awful.util.spawn(config.system.filemanager) end),
  uniarg:key_repeat({ modkey, "Mod1", }, "p", function () awful.util.spawn("putty") end),
  uniarg:key_repeat({ modkey, "Mod1", }, "r", function () awful.util.spawn("remmina") end),
  uniarg:key_repeat({ modkey,         }, "i", function () awful.util.spawn(config.editor.primary) end),
  uniarg:key_repeat({ modkey, "Shift" }, "i", function () awful.util.spawn(config.editor.secondary) end),
  uniarg:key_repeat({ modkey,         }, "b", function () awful.util.spawn(config.browser.primary) end),
  uniarg:key_repeat({ modkey, "Shift" }, "b", function () awful.util.spawn(config.browser.secondary) end),
  uniarg:key_repeat({ modkey, "Mod1", }, "v", function () awful.util.spawn("virtualbox") end),
  uniarg:key_repeat({ modkey, "Shift" }, "\\", function() awful.util.spawn("kmag") end),

  --- the rest
  uniarg:key_repeat({}, "XF86AudioPrev", function () awful.util.spawn("mpc prev") end),
  uniarg:key_repeat({}, "XF86AudioNext", function () awful.util.spawn("mpc next") end),
  awful.key({}, "XF86AudioPlay", function () awful.util.spawn("mpc toggle") end),
  awful.key({}, "XF86AudioStop", function () awful.util.spawn("mpc stop") end),

  uniarg:key_numarg({}, "XF86AudioRaiseVolume",
    function ()
      awful.util.spawn("amixer sset Master 5%+")
    end,
    function (n)
      awful.util.spawn("amixer sset Master " .. n .. "%+")
  end),

  uniarg:key_numarg({}, "XF86AudioLowerVolume",
    function ()
      awful.util.spawn("amixer sset Master 5%-")
    end,
    function (n)
      awful.util.spawn("amixer sset Master " .. n .. "%-")
  end),

  awful.key({}, "XF86AudioMute",    function () awful.util.spawn("amixer sset Master toggle") end),
  awful.key({}, "XF86AudioMicMute", function () awful.util.spawn("amixer sset Mic toggle") end),
  awful.key({}, "XF86ScreenSaver",  function () awful.util.spawn("xscreensaver-command -l") end),
  awful.key({}, "XF86WebCam",       function () awful.util.spawn("cheese") end),

  uniarg:key_numarg({}, "XF86MonBrightnessUp",
    function ()
      awful.util.spawn("xbacklight -inc 10")
    end,
    function (n)
      awful.util.spawn("xbacklight -inc " .. n)
  end),

  uniarg:key_numarg({}, "XF86MonBrightnessDown",
    function ()
      awful.util.spawn("xbacklight -dec 10")
    end,
    function (n)
      awful.util.spawn("xbacklight -dec " .. n)
  end),

  awful.key({},         "XF86WLAN",    function () awful.util.spawn("nm-connection-editor") end),
  awful.key({},         "XF86Display", function () awful.util.spawn("arandr") end),
  awful.key({},         "Print",       function () awful.util.spawn("xfce4-screenshooter") end),
  uniarg:key_repeat({}, "XF86Launch1", function () awful.util.spawn(config.terminal) end),
  awful.key({},         "XF86Sleep",   function () awful.util.spawn("systemctl suspend") end),
  awful.key({ modkey }, "XF86Sleep",   function () awful.util.spawn("systemctl hibernate") end),

  --- hacks for Thinkpad W530 FN mal-function
  uniarg:key_repeat({ modkey },            "F10",  function () awful.util.spawn("mpc prev") end),
  awful.key({         modkey },            "F11",  function () awful.util.spawn("mpc toggle") end),
  uniarg:key_repeat({ modkey },            "F12",  function () awful.util.spawn("mpc next") end),
  uniarg:key_repeat({ modkey, "Control" }, "Left", function () awful.util.spawn("mpc prev") end),
  awful.key(        { modkey, "Control" }, "Down", function () awful.util.spawn("mpc toggle") end),
  uniarg:key_repeat({ modkey, "Control" }, "Right",function () awful.util.spawn("mpc next") end),
  awful.key(        { modkey, "Control" }, "Up",   function () awful.util.spawn("gnome-alsamixer") end),

  uniarg:key_numarg({ modkey, "Shift" }, "Left",
    function ()
      awful.util.spawn("mpc seek -1%")
    end,
    function (n)
      awful.util.spawn("mpc seek -" .. n .. "%")
  end),

  uniarg:key_numarg({ modkey, "Shift" }, "Right",
    function ()
      awful.util.spawn("mpc seek +1%")
    end,
    function (n)
      awful.util.spawn("mpc seek +" .. n .. "%")
  end),

  uniarg:key_numarg({ modkey, "Shift" }, "Down",
    function ()
      awful.util.spawn("mpc seek -10%")
    end,
    function (n)
      awful.util.spawn("mpc seek -" .. n .. "%")
  end),

  uniarg:key_numarg({ modkey, "Shift" }, "Up",
    function ()
      awful.util.spawn("mpc seek +10%")
    end,
    function (n)
      awful.util.spawn("mpc seek +" .. n .. "%")
  end),
  nil
)

-- }}}
-- {{{ client management

--- operation
binds.clientkeys = awful.util.table.join(
  awful.key({ modkey,           }, "f", func.client_fullscreen),
  awful.key({ modkey,           }, "m", func.client_maximize),
  awful.key({ modkey, "Shift"   }, "c", func.client_kill),
  awful.key({ "Mod1",           }, "F4", func.client_kill),

  awful.key({ modkey, "Shift"   }, "Delete", function (c)
      -- sends SIGKILL to X window currently in focus
      awful.util.spawn("killwindow")
  end),

  -- move client to sides, i.e., sidelining
  awful.key({ modkey,           }, "Left", func.client_sideline_left),
  awful.key({ modkey,           }, "Right", func.client_sideline_right),
  awful.key({ modkey,           }, "Up", func.client_sideline_top),
  awful.key({ modkey,           }, "Down", func.client_sideline_bottom),

  -- extend client sides
  uniarg:key_numarg({ modkey, "Mod1"    }, "Left",
    func.client_sideline_extend_left,
    function (n, c)
      func.client_sideline_extend_left(c, n)
  end),

  uniarg:key_numarg({ modkey, "Mod1"    }, "Right",
    func.client_sideline_extend_right,
    function (n, c)
      func.client_sideline_extend_right(c, n)
  end),

  uniarg:key_numarg({ modkey, "Mod1"    }, "Up",
    func.client_sideline_extend_top,
    function (n, c)
      func.client_sideline_extend_top(c, n)
  end),

  uniarg:key_numarg({ modkey, "Mod1"    }, "Down",
    func.client_sideline_extend_bottom,
    function (n, c)
      func.client_sideline_extend_bottom(c, n)
  end),

  -- shrink client sides
  uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Left",
    func.client_sideline_shrink_left,
    function (n, c)
      func.client_sideline_shrink_left(c, n)
    end
  ),

  uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Right",
    func.client_sideline_shrink_right,
    function (n, c)
      func.client_sideline_shrink_right(c, n)
    end
  ),

  uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Up",
    func.client_sideline_shrink_top,
    function (n, c)
      func.client_sideline_shrink_top(c, n)
    end
  ),

  uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Down",
    func.client_sideline_shrink_bottom,
    function (n, c)
      func.client_sideline_shrink_bottom(c, n)
    end
  ),

  -- maximize/minimize
  awful.key({ modkey, "Shift"   }, "m", func.client_minimize),
  awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle),
  awful.key({ modkey,           }, "t", func.client_toggle_top),
  awful.key({ modkey,           }, "s", func.client_toggle_sticky),
  awful.key({ modkey,           }, ",", func.client_maximize_horizontal),
  awful.key({ modkey,           }, ".", func.client_maximize_vertical),
  awful.key({ modkey,           }, "[", func.client_opaque_less),
  awful.key({ modkey,           }, "]", func.client_opaque_more),
  awful.key({ modkey, 'Shift'   }, "[", func.client_opaque_off),
  awful.key({ modkey, 'Shift'   }, "]", func.client_opaque_on),
  awful.key({ modkey, "Control" }, "Return", func.client_swap_with_master),
  nil
)
-- }}}
-- {{{ Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9, plus 0.
for i = 1, 10 do
  local keycode = "#" .. i+9

  binds.globalkeys = awful.util.table.join(
    binds.globalkeys,

    awful.key({ modkey }, keycode,
      function () tag = get_tag(i, mouse.screen) if tag then tag:view_only() end
    end),

    awful.key({ modkey, "Control" }, keycode,
      function () tag = get_tag(i, mouse.screen) if tag then awful.tag.viewtoggle(tag) end
    end),

    awful.key({ modkey, "Shift" }, keycode,
      function ()
        if client.focus then
          tag = get_tag(i, client.focus.screen)
          if tag then
            awful.client.movetotag(tag)
          end
        end
    end),

    awful.key({ modkey, "Control", "Shift" }, keycode,
      function ()
        if client.focus then
          tag = get_tag(i, client.focus.screen)
          if tag then
            awful.client.toggletag(tag)
          end
        end
    end),

    nil
  )
end
-- }}}
-- {{{ client buttons
binds.clientbuttons = awful.util.table.join(
  awful.button({ }, 1, function (c)
      if awful.client.focus.filter(c) then
        client.focus = c
        c:raise()
      end
  end),
  awful.button({ modkey }, 1, awful.mouse.client.move),
  awful.button({ modkey }, 3, awful.mouse.client.resize)
)
-- }}}


function binds.init()
  root.keys(binds.globalkeys)
end

return binds
