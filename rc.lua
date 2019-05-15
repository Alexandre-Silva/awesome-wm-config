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

if os.getenv("AWESOME_DEBUG") then
  require("repetitive")
end

local bashets = require("bashets") -- bashets config: https://gitorious.org/bashets/pages/Brief_Introduction
local beautiful = require("beautiful")
local custom = require('custom')
local util = require('util')
local gears = require("gears")
local naughty = require("naughty")
local uniarg = require("uniarg")

local awesome = awesome
local screen = screen
local client = client
-- }}}


-- do not use letters, which shadow access key to menu entry
awful.menu.menu_keys.down = { "Down", ".", ">", "'", "\"", }
awful.menu.menu_keys.up = { "Up", ",", "<", ";", ":", }
awful.menu.menu_keys.enter = { "Right", "]", "}", "=", "+", }
awful.menu.menu_keys.back = { "Left", "[", "{", "-", "_", }
awful.menu.menu_keys.exec = { "Return", "Space", }
awful.menu.menu_keys.close = { "Escape", "BackSpace", }

naughty.config.presets.low.opacity = custom.config.property.default_naughty_opacity
naughty.config.presets.normal.opacity = custom.config.property.default_naughty_opacity
naughty.config.presets.critical.opacity = custom.config.property.default_naughty_opacity

bashets.set_script_path(awful.util.getdir("config") .. "/modules/bashets/")

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
local awesome_client_tags_fname = cachedir .. "/awesome-client-tags-" ..  XDG_SESSION_ID

awesome.connect_signal(
  "exit",
  function (restart)
    if not restart then
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
  local function init_theme(theme_name)
    local theme_path = config_path .. "/themes/" .. theme_name .. "/theme.lua"
    beautiful.init(theme_path)
  end

  init_theme("zenburn")
  -- init_theme("powerarrow-dark")

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
  custom.config.wallpaper_change_interval,
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
bashets.start()

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
      placement = awful.placement.no_overlap + awful.placement.no_offscreen,
      opacity = custom.config.property.default_naughty_opacity,
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
    callback = function (_) end,
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
client.connect_signal("manage", custom.structure.manage_client)
client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- XDG style autostart with "dex"
-- HACK continue

local awesome_pid = io.popen('pgrep awesome | tail -n 1'):read('*n')
local session_file = '/tmp/awesome.' .. awesome_pid
if not util.file_exists(session_file) then
  local f = io.open(session_file, 'w')
  f:write('')
  f:close()

  if not os.getenv("AWESOME_DEBUG") then
    awful.spawn.with_shell("dex -a -e awesome")
    awful.spawn.with_shell("hash awesome_on_launch.sh && awesome_on_launch.sh")
  end

end

custom.func.client_opaque_on(nil) -- start xcompmgr
