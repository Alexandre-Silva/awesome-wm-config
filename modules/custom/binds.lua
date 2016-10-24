local awful = require("awful")
local uniarg = require("uniarg")

local widgets = require("custom.widgets")
local func = require("custom.func")
local structure = require("custom.structure")
local default = require("custom.default")
local config = require("custom.config")


local binds = {}

local globalkeys = nil
local clientkeys = nil
local clientbuttons = nil

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other custom.config.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"
binds.modkey = modkey

-- {{{ Utils
do
  local cachedir = awful.util.getdir("cache")
  local awesome_tags_fname = cachedir .. "/awesome-tags"

  -- test whether screen 1 tag file exists
  local f = io.open(awesome_tags_fname .. ".0", "r")
  if f then
    local old_scr_count = tonumber(f:read("*l"))
    f:close()
    os.remove(awesome_tags_fname .. ".0")

    local new_scr_count = screen.count()
    local count = {}
    local scr_count = math.min(new_scr_count, old_scr_count)

    if scr_count>0 then
      for s = 1, scr_count do
        count[s] = 1
      end

      for s = 1, old_scr_count do
        local count_index = math.min(s, scr_count)
        local fname = awesome_tags_fname .. "." .. s
        for tagname in io.lines(fname) do
          local tag = awful.tag.add(tagname,
                                    {
                                      screen = count_index,
                                      layout = default.property.layout,
                                      mwfact = default.property.mwfact,
                                      nmaster = default.property.nmaster,
                                      ncol = default.property.ncol,
                                    }
          )
          awful.tag.move(count[count_index], tag)

          count[count_index] = count[count_index]+1
        end
        os.remove(fname)
      end
    end

    for s = 1, screen.count() do
      local fname = awesome_tags_fname .. "-selected." .. s
      f = io.open(fname, "r")
      if f then
        local tag = awful.tag.gettags(s)[tonumber(f:read("*l"))]
        if tag then
          awful.tag.viewonly(tag)
        end
        f:close()
      end
      os.remove(fname)
    end

  else
    local tag = awful.tag.add(os.getenv("USER"),
                              {
                                screen = 1,
                                layout = default.property.layout,
                                mwfact = default.property.mwfact,
                                nmaster = default.property.nmaster,
                                ncol = default.property.ncol,
                              }
    )
    awful.tag.viewonly(tag)

    awful.tag.add("nil",
                  {
                    screen = 2,
                    layout = default.property.layout,
                    mwfact = default.property.mwfact,
                    nmaster = default.property.nmaster,
                    ncol = default.property.ncol,
                  }
    )

  end
end

-- Create a new at screen (creates tag iff name is not nill)
-- @param screen Screen where to create the tag
-- @param name Tag's name
local function new_tag(screen, name)
  tag = nil
  if text and #text>0 then
    tag = awful.tag.add(text)
    awful.tag.setscreen(tag, scr)
    awful.tag.move(#tags+1, tag)
    awful.tag.viewonly(tag)
  end
  return tag
end

-- Ask for new tag's name and creates a tag
-- @param screen Screen where to create the tag
local function promp_new_tag(screen)
  tag = nil
  awful.prompt.run(
    {prompt = "<span fgcolor='red'>new tag: </span>"},
    widgets.promptbox[scr].widget,
    function(text) tag = new_tag(screen,text) end,
    nil)

  return tag
end

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
    return prompt_new_tag(screen)
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
globalkeys = awful.util.table.join(
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
globalkeys = awful.util.table.join(
  globalkeys,

  --- restart/quit/info
  awful.key({ modkey, "Control" }, "r", awesome.restart),
  awful.key({ modkey, "Shift"   }, "q", awesome.quit),
  awful.key({ modkey            }, "\\", func.systeminfo),
  awful.key({modkey             }, "F1", func.help),
  awful.key({ "Ctrl", "Shift"   }, "Escape", function () awful.util.spawn(config.system.taskmanager) end),

  --- Layout
  uniarg:key_repeat({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
  uniarg:key_repeat({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

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

  -- dynamic tagging
  awful.key({ modkey, "Ctrl", "Mod1" }, "t", function ()
      option.tag_persistent_p = not option.tag_persistent_p
      local msg = nil
      if option.tag_persistent_p then
        msg = "Tags will persist across exit/restart."
      else
        msg = "Tags will <span fgcolor='red'>NOT</span> persist across exit/restart."
      end
      naughty.notify({
          preset = naughty.config.presets.normal,
          title="Tag persistence",
          text=msg,
          timeout = 1,
          screen = mouse.screen,
      })
  end),

  --- add/delete/rename
  awful.key({modkey}, "a", func.tag_add_after),
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
clientkeys = awful.util.table.join(
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

  globalkeys = awful.util.table.join(
    globalkeys,

    awful.key({ modkey }, keycode,
      function () tag = get_tag(i, mouse.screen) if tag then awful.tag.viewonly(tag) end
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
local clientbuttons = awful.util.table.join(
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
  root.keys(globalkeys)
end

config.globalkeys = globalkeys
config.clientkeys = clientkeys
config.clientbuttons = clientbuttons

return binds
