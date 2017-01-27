-- Imports {{{
local awful = require("awful")
awful.rules = require("awful.rules")

require("awful.autofocus")
require("awful.dbus")
require("awful.remote")

local config_path = awful.util.getdir("config")
-- local config_path = "/home/alex/projects/awesome-wm-config"
package.path = config_path .. "/?.lua;" .. package.path
package.path = config_path .. "/?/init.lua;" .. package.path
package.path = config_path .. "/modules/?.lua;" .. package.path
package.path = config_path .. "/modules/?/init.lua;" .. package.path


local autostart = require("autostart")
local bashets = require("bashets") -- bashets config: https://gitorious.org/bashets/pages/Brief_Introduction
local beautiful = require("beautiful")
local custom = require('custom')
local gears = require("gears")
local math = require("math")
local menubar = require("menubar")
local naughty = require("naughty")
local uniarg = require("uniarg")
local util = require("util")
local vicious = require("vicious")
local wibox = require("wibox")
-- }}}

-- do not use letters, which shadow access key to menu entry
awful.menu.menu_keys.down = { "Down", ".", ">", "'", "\"", }
awful.menu.menu_keys.up = {  "Up", ",", "<", ";", ":", }
awful.menu.menu_keys.enter = { "Right", "]", "}", "=", "+", }
awful.menu.menu_keys.back = { "Left", "[", "{", "-", "_", }
awful.menu.menu_keys.exec = { "Return", "Space", }
awful.menu.menu_keys.close = { "Escape", "BackSpace", }

naughty.config.presets.low.opacity = custom.default.property.default_naughty_opacity
naughty.config.presets.normal.opacity = custom.default.property.default_naughty_opacity
naughty.config.presets.critical.opacity = custom.default.property.default_naughty_opacity

do
  local config_path = awful.util.getdir("config")
  bashets.set_script_path(config_path .. "/modules/bashets/")
end

-- Error handling {{{
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
  naughty.notify({ preset = naughty.config.presets.critical,
                   title = "Oops, there were errors during startup!",
                   text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
  local in_error = false
  awesome.connect_signal("debug::error", function (err)
                           -- Make sure we don't go into an endless error loop
                           if in_error then return end
                           in_error = true

                           naughty.notify({ preset = naughty.config.presets.critical,
                                            title = "Oops, an error happened!",
                                            text = err })
                           in_error = false
  end)
end
-- }}}
-- HACK! prevent Awesome start autostart items multiple times in a session {{{
-- cause: in-place restart by awesome.restart, xrandr change
-- idea:
-- * create a file awesome-autostart-once when first time "dex" autostart items (at the end of this file)
-- * only "rm" this file when awesome.quit

-- consider removing this persystency thingie as it is not beeing used(see
-- custom.binds for copy-paste if this)
local cachedir = awful.util.getdir("cache")
local XDG_SESSION_ID = os.getenv("XDG_SESSION_ID") or "0"
local awesome_tags_fname = cachedir .. "/awesome-tags"
local awesome_autostart_once_fname = cachedir .. "/awesome-autostart-once-" .. XDG_SESSION_ID
local awesome_client_tags_fname = cachedir .. "/awesome-client-tags-" ..  XDG_SESSION_ID

awesome.connect_signal(
  "exit",
  function (restart)
    if not restart then
      awful.spawn.with_shell("rm -rf " .. awesome_autostart_once_fname)
      bashets.stop()
    end
end)

-- wrapps default exit/restart functions with a prompt asking for confirmation
for fname in ipairs({"quit", "restart"}) do
  custom.orig[fname] = awesome[fname]
  awesome[fname] = function ()
    custom.func.prompt_yes_no(fname, custom.orig[fname] )
  end
end
-- }}}
-- Theme {{{
do
  local config_path = awful.util.getdir("config")
  local function init_theme(theme_name)
    local theme_path = config_path .. "/themes/" .. theme_name .. "/theme.lua"
    beautiful.init(theme_path)
  end

  init_theme("zenburn")

  awful.spawn.with_shell("hsetroot -solid '#000000'")
end
-- }}}
-- Wallpaper {{{
local function set_wallpaper(s)
  -- Wallpaper
  if beautiful.wallpaper then
    local wallpaper = beautiful.wallpaper
    -- If wallpaper is a function, call it with the screen
    if type(wallpaper) == "function" then
      wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)
  end
end

-- randomly select a background picture
function custom.func.change_wallpaper(s)
  if custom.option.wallpaper_change_p then
    awful.spawn.with_shell("cd " .. config_path .. "/wallpaper/; ./my-wallpaper-pick.sh")
  end
end

custom.timer.change_wallpaper = gears.timer.start_new(
  custom.default.wallpaper_change_interval,
  function ()
    custom.func.change_wallpaper()
    return true
end)
custom.func.change_wallpaper(nil)

--Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
-- screen.connect_signal("property::geometry", change_wallpaper)
screen.connect_signal("property::geometry", custom.func.change_wallpaper)
-- }}}

custom.widgets.init()
uniarg:init(custom.widgets.uniarg)
custom.structure.init()
custom.binds.init()

-- Rules {{{
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {

  -- All clients will match this rule.
  {
    rule = { },
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = custom.binds.clientkeys,
      buttons = custom.binds.clientbuttons,
      screen = awful.screen.preferred,
      placement = awful.placement.no_overlap+awful.placement.no_offscreen,
      opacity = custom.default.property.default_naughty_opacity,
      size_hints_honor = false,
    }
  },

  {
    rule = { class = "MPlayer" },
    properties = {
      floating = true,
      opacity = 1,
    }
  },

  {
    rule = { class = "gimp" },
    properties = {
      floating = true,
    },
  },

  {
    rule = { class = "Xdialog" },
    properties = {
      floating = true,
    },
  },

  --[[
    Set Firefox to always map on tags number 2 of screen 1.
    { rule = { class = "Firefox" },
    properties = { screen = 1, tag = "2" } },
  --]]

  {
    rule = { class = "Kmag" },
    properties = {
      ontop = true,
      floating = true,
      opacity = 0.8,
      sticky = true,
    },
    callback = function (c)
    end,
  },


  {
    rule = { class = "Conky" },
    properties = {
      sticky = true,
      opacity = 0.4,
      focusable = false,
      ontop = false,
    },
  }

}
-- }}}
-- Signals {{{
-- Signal function to execute when a new client appears.
client.connect_signal(
  "manage",
  function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
                       if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
                       and awful.client.focus.filter(c) then
                         client.focus = c
                       end
    end)

    if not startup then
      -- Set the windows at the slave,
      -- i.e. put it at the end of others instead of setting it master.
      -- awful.client.setslave(c)

      -- Put windows in a smart way, only if they does not set an initial position.
      if not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_overlap(c)
        awful.placement.no_offscreen(c)
      end
    end

    local titlebars_enabled = true
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then

      -- buttons for the titlebar
      local buttons = awful.util.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
      )

      -- Widgets that are aligned to the left
      local left_layout = wibox.layout.fixed.horizontal()
      left_layout:add(awful.titlebar.widget.iconwidget(c))
      left_layout:buttons(buttons)

      -- Widgets that are aligned to the right
      local right_layout = wibox.layout.fixed.horizontal()
      right_layout:add(awful.titlebar.widget.floatingbutton(c))
      right_layout:add(awful.titlebar.widget.maximizedbutton(c))
      right_layout:add(awful.titlebar.widget.stickybutton(c))
      right_layout:add(awful.titlebar.widget.ontopbutton(c))
      right_layout:add(awful.titlebar.widget.closebutton(c))

      -- The title goes in the middle
      local middle_layout = wibox.layout.flex.horizontal()
      local title = awful.titlebar.widget.titlewidget(c)
      title:set_align("center")
      middle_layout:add(title)
      middle_layout:buttons(buttons)

      -- Now bring it all together
      local layout = wibox.layout.align.horizontal()
      layout:set_left(left_layout)
      layout:set_right(right_layout)
      layout:set_middle(middle_layout)

      awful.titlebar(c):set_widget(layout)

      -- hide the titlebar by default (it takes space)
      awful.titlebar.hide(c)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
client.connect_signal("manage", custom.func.client_manage_tag)
-- }}}


-- XDG style autostart with "dex"
-- HACK continue
awful.spawn.with_shell("if ! [ -e " .. awesome_autostart_once_fname .. " ]; then dex -a -e awesome; touch " .. awesome_autostart_once_fname .. "; fi")
custom.func.client_opaque_on(nil) -- start xcompmgr
