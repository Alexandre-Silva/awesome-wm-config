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

local capi = {
  tag = tag,
  screen = screen,
  client = client,
}

-- do not use letters, which shadow access key to menu entry
awful.menu.menu_keys.down = { "Down", ".", ">", "'", "\"", }
awful.menu.menu_keys.up = {  "Up", ",", "<", ";", ":", }
awful.menu.menu_keys.enter = { "Right", "]", "}", "=", "+", }
awful.menu.menu_keys.back = { "Left", "[", "{", "-", "_", }
awful.menu.menu_keys.exec = { "Return", "Space", }
awful.menu.menu_keys.close = { "Escape", "BackSpace", }

local modkey = custom.binds.modkey

naughty.config.presets.low.opacity = custom.default.property.default_naughty_opacity
naughty.config.presets.normal.opacity = custom.default.property.default_naughty_opacity
naughty.config.presets.critical.opacity = custom.default.property.default_naughty_opacity

do
  local config_path = awful.util.getdir("config")
  bashets.set_script_path(config_path .. "/modules/bashets/")
end

-- {{{ Error handling
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
-- {{{ HACK! prevent Awesome start autostart items multiple times in a session
-- cause: in-place restart by awesome.restart, xrandr change
-- idea:
-- * create a file awesome-autostart-once when first time "dex" autostart items (at the end of this file)
-- * only "rm" this file when awesome.quit

-- consider removing this persystency thingie as it is not beeing used(see
-- custom.binds for copy-paste if this)
local cachedir = awful.util.getdir("cache")
local awesome_tags_fname = cachedir .. "/awesome-tags"
local awesome_autostart_once_fname = cachedir .. "/awesome-autostart-once-" .. os.getenv("XDG_SESSION_ID")
local awesome_client_tags_fname = cachedir .. "/awesome-client-tags-" .. os.getenv("XDG_SESSION_ID")

do
    awesome.connect_signal("exit", function (restart)
        local scrcount = screen.count()
        -- save number of screens, used for check proper tag recording
        do
            local f = io.open(awesome_tags_fname .. ".0", "w+")
            if f then
                f:write(string.format("%d", scrcount) .. "\n")
                f:close()
            end
        end
        -- save current tags
        for s = 1, scrcount do
            local f = io.open(awesome_tags_fname .. "." .. s, "w+")
            if f then
                local tags = awful.tag.gettags(s)
                for _, tag in ipairs(tags) do
                    f:write(tag.name .. "\n")
                end
                f:close()
            end
            f = io.open(awesome_tags_fname .. "-selected." .. s, "w+")
            if f then
                f:write(awful.tag.getidx() .. "\n")
                f:close()
            end
        end
        custom.func.client_opaque_off(nil) -- prevent compmgr glitches
        if not restart then
            awful.util.spawn_with_shell("rm -rf " .. awesome_autostart_once_fname)
            awful.util.spawn_with_shell("rm -rf " .. awesome_client_tags_fname)
            if not custom.option.tag_persistent_p then
                awful.util.spawn_with_shell("rm -rf " .. awesome_tags_fname .. '*')
            end
            bashets.stop()
        else -- if restart, save client tags
            -- save tags for each client
            awful.util.mkdir(awesome_client_tags_fname)
            -- !! avoid awful.util.spawn_with_shell("mkdir -p " .. awesome_client_tags_fname)
            -- race condition (whether awesome_client_tags_fname is created) due to asynchrony of "spawn_with_shell"
            for _, c in ipairs(client.get()) do
                local client_id = c.pid .. '-' .. c.window
                local f = io.open(awesome_client_tags_fname .. '/' .. client_id, 'w+')
                if f then
                    for _, t in ipairs(c:tags()) do
                        f:write(t.name .. "\n")
                    end
                    f:close()
                end
            end

        end
    end)
end

for _,fname in pairs({"quit", "restart"}) do
  custom.orig[fname] = awesome[fname]
  awesome[fname] = function ()
    local scr = mouse.screen
    awful.prompt.run({prompt = fname .. " (type 'yes' to confirm)? "},
      custom.widgets.promptbox[scr].widget,
      function (t)
        if string.lower(t) == 'yes' then
          custom.orig[fname]()
        end
      end,
      function (t, p, n)
        return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
    end)
  end
end
-- }}}
-- {{{ Variable definitions

do
    local config_path = awful.util.getdir("config")
    local function init_theme(theme_name)
        local theme_path = config_path .. "/themes/" .. theme_name .. "/theme.lua"
        beautiful.init(theme_path)
    end

    init_theme("zenburn")

    awful.util.spawn_with_shell("hsetroot -solid '#000000'")

    -- randomly select a background picture
    --{{
    function custom.func.change_wallpaper()
        if custom.option.wallpaper_change_p then
            awful.util.spawn_with_shell("cd " .. config_path .. "/wallpaper/; ./my-wallpaper-pick.sh")
        end
    end

    custom.timer.change_wallpaper= timer({timeout = custom.default.wallpaper_change_interval})

    custom.timer.change_wallpaper:connect_signal("timeout", custom.func.change_wallpaper)

    custom.timer.change_wallpaper:connect_signal("property::timeout",
    function ()
        custom.timer.change_wallpaper:stop()
        custom.timer.change_wallpaper:start()
    end
    )

    custom.timer.change_wallpaper:start()
    -- first trigger
    custom.func.change_wallpaper()
    --}}
end
-- }}}

--[[
-- {{{ Wallpaper
if beautiful.wallpaper then
for s = 1, screen.count() do
gears.wallpaper.maximized(beautiful.wallpaper, s, true)
end
end
-- }}}
--]]

custom.structure.init()

-- {{{ Wibox
custom.widgets.memusage = wibox.widget.textbox()
vicious.register(custom.widgets.memusage, vicious.widgets.mem,
  "<span fgcolor='yellow'>$1% ($2MB/$3MB)</span>", 3)
do
    local prog=custom.config.system.taskmanager
    local started=false
    custom.widgets.memusage:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        if started then
            awful.util.spawn("pkill -f '" .. prog .. "'")
        else
            awful.util.spawn(prog)
        end
        started=not started
    end)
    ))
end

custom.widgets.bat0 = awful.widget.progressbar()
custom.widgets.bat0:set_width(8)
custom.widgets.bat0:set_height(10)
custom.widgets.bat0:set_vertical(true)
custom.widgets.bat0:set_background_color("#494B4F")
custom.widgets.bat0:set_border_color(nil)
custom.widgets.bat0:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 10 },
  stops = { { 0, "#AECF96" }, { 0.5, "#88A175" }, { 1, "#FF5656" }}})
vicious.register(custom.widgets.bat0, vicious.widgets.bat, "$2", 61, "BAT1")
do
    local prog="gnome-control-center power"
    local started=false
    custom.widgets.bat0:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        if started then
            awful.util.spawn("pkill -f '" .. prog .. "'")
        else
            awful.util.spawn(prog)
        end
        started=not started
    end)
    ))
end

custom.widgets.mpdstatus = wibox.widget.textbox()
custom.widgets.mpdstatus:set_ellipsize("end")
vicious.register(custom.widgets.mpdstatus, vicious.widgets.mpd,
  function (mpdwidget, args)
    local text = nil
    local state = args["{state}"]
    if state then
      if state == "Stop" then
        text = ""
      else
        text = args["{Artist}"]..' - '.. args["{Title}"]
      end
      return '<span fgcolor="light green"><b>[' .. state .. ']</b> <small>' .. text .. '</small></span>'
    end
    return ""
  end, 1)
-- http://git.sysphere.org/vicious/tree/README
custom.widgets.mpdstatus = wibox.layout.constraint(custom.widgets.mpdstatus, "max", 180, nil)
do
    custom.widgets.mpdstatus:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        awful.util.spawn("mpc toggle")
    end),
    awful.button({ }, 2, function ()
        awful.util.spawn("mpc prev")
    end),
    awful.button({ }, 3, function ()
        awful.util.spawn("mpc next")
    end),
    awful.button({ }, 4, function ()
        awful.util.spawn("mpc seek -1%")
    end),
    awful.button({ }, 5, function ()
        awful.util.spawn("mpc seek +1%")
    end)
    ))
end

custom.widgets.volume = wibox.widget.textbox()
vicious.register(custom.widgets.volume, vicious.widgets.volume,
  "<span fgcolor='cyan'>$1%$2</span>", 1, "Master")
do
    local prog="gnome-alsamixer"
    local started=false
    custom.widgets.volume:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        if started then
            awful.util.spawn("pkill -f '" .. prog .. "'")
        else
            awful.util.spawn(prog)
        end
        started=not started
    end),
    awful.button({ }, 2, function ()
        awful.util.spawn("amixer sset Mic toggle")
    end),
    awful.button({ }, 3, function ()
        awful.util.spawn("amixer sset Master toggle")
    end),
    awful.button({ }, 4, function ()
        awful.util.spawn("amixer sset Master 1%-")
    end),
    awful.button({ }, 5, function ()
        awful.util.spawn("amixer sset Master 1%+")
    end)
    ))
end

custom.widgets.date = wibox.widget.textbox()
vicious.register(custom.widgets.date, vicious.widgets.date, "%d-%m-%y %X", 1)
do
    local prog1="gnome-control-center datetime"
    local started1=false
    local prog2="gnome-control-center region"
    local started2=false
    custom.widgets.date:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        if started1 then
            awful.util.spawn("pkill -f '" .. prog1 .. "'")
        else
            awful.util.spawn(prog1)
        end
        started1=not started1
    end),
    awful.button({ }, 3, function ()
        if started2 then
            awful.util.spawn("pkill -f '" .. prog2 .. "'")
        else
            awful.util.spawn(prog2)
        end
        started2=not started2
    end)
    ))
end

-- Create a wibox for each screen and add it

custom.widgets.uniarg = {}
custom.widgets.wibox = {}
custom.widgets.promptbox = {}
custom.widgets.layoutbox = {}
custom.widgets.taglist = {}

custom.widgets.taglist.buttons = awful.util.table.join(
awful.button({ }, 1, awful.tag.viewonly),
awful.button({ modkey }, 1, awful.client.movetotag),
awful.button({ }, 2, awful.tag.viewtoggle),
awful.button({ modkey }, 2, awful.client.toggletag),
awful.button({ }, 3, function (t)
  custom.func.tag_action_menu(t)
end),
awful.button({ modkey }, 3, awful.tag.delete),
awful.button({ }, 4, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end),
awful.button({ }, 5, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end)
)

custom.widgets.tasklist = {}
custom.widgets.tasklist.buttons = awful.util.table.join(

awful.button({ }, 1, function (c)
    if c == client.focus then
        c.minimized = true
    else
        -- Without this, the following
        -- :isvisible() makes no sense
        c.minimized = false
        if not c:isvisible() then
            awful.tag.viewonly(c:tags()[1])
        end
        -- This will also un-minimize
        -- the client, if needed
        client.focus = c
        c:raise()
    end
end),

awful.button({ }, 2, function (c)
  custom.func.clients_on_tag()
end),

awful.button({ modkey }, 2, function (c)
    custom.func.all_clients()
end),

awful.button({ }, 3, function (c)
  custom.func.client_action_menu(c)
end),

awful.button({ }, 4, function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
end),

awful.button({ }, 5, function ()
    awful.client.focus.byidx(1)
    if client.focus then client.focus:raise() end
end))

-- start bashets
bashets.start()

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    custom.widgets.promptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    custom.widgets.layoutbox[s] = awful.widget.layoutbox(s)
    custom.widgets.layoutbox[s]:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.layout.inc(custom.config.layouts, 1) end),
    awful.button({ }, 3, function () awful.layout.inc(custom.config.layouts, -1) end),
    awful.button({ }, 4, function () awful.layout.inc(custom.config.layouts, -1) end),
    awful.button({ }, 5, function () awful.layout.inc(custom.config.layouts, 1) end),
    nil
    ))
    -- Create a taglist widget
    custom.widgets.taglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, custom.widgets.taglist.buttons)

    -- Create a textbox showing current universal argument
    custom.widgets.uniarg[s] = wibox.widget.textbox()
    -- Create a tasklist widget
    custom.widgets.tasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, custom.widgets.tasklist.buttons)

    -- Create the wibox
    custom.widgets.wibox[s] = awful.wibox({ position = "top", height = "18", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(custom.widgets.launcher)
    left_layout:add(custom.widgets.taglist[s])
    left_layout:add(custom.widgets.uniarg[s])
    left_layout:add(custom.widgets.promptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(custom.widgets.cpuusage)
    right_layout:add(custom.widgets.memusage)
    right_layout:add(custom.widgets.bat0)
    right_layout:add(custom.widgets.mpdstatus)
    --right_layout:add(custom.widgets.audio_volume)
    right_layout:add(custom.widgets.volume)
    right_layout:add(custom.widgets.date)
    --right_layout:add(custom.widgets.textclock)
    right_layout:add(custom.widgets.layoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(custom.widgets.tasklist[s])
    layout:set_right(right_layout)

    custom.widgets.wibox[s]:set_widget(layout)
end

util.taglist.set_taglist(custom.widgets.taglist)
-- }}}

uniarg:init(custom.widgets.uniarg)
custom.binds.init()

-- {{{ Rules
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
            buttons = clientbuttons,
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
      properties = { tag = tags[1][2] } },
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
-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
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
-- client.connect_signal("focus", function(c) c.border_color = "#a5e12d" end)

client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

custom.func.client_manage_tag = function (c, startup)
    if startup then
        local client_id = c.pid .. '-' .. c.window

        local fname = awesome_client_tags_fname .. '/' .. client_id
        local f = io.open(fname, 'r')

        if f then
            local tags = {}
            for tag in io.lines(fname) do
                tags = awful.util.table.join(tags, {util.tag.name2tag(tag)})
            end
            -- remove the file after using it to reduce clutter
            os.remove(fname)

            if #tags>0 then
                c:tags(tags)
                -- set c's screen to that of its first (often the only) tag
                -- this prevents client to be placed off screen in case of randr change (on the number of screen)
                c.screen = awful.tag.getscreen(tags[1])
                awful.placement.no_overlap(c)
                awful.placement.no_offscreen(c)
            end
        end
    end
end

client.connect_signal("manage", custom.func.client_manage_tag)

-- }}}

-- disable startup-notification globally
-- prevent unintended mouse cursor change
custom.orig.awful_util_spawn = awful.util.spawn
awful.util.spawn = function (s)
    custom.orig.awful_util_spawn(s, false)
end


-- XDG style autostart with "dex"
-- HACK continue
awful.util.spawn_with_shell("if ! [ -e " .. awesome_autostart_once_fname .. " ]; then dex -a -e awesome; touch " .. awesome_autostart_once_fname .. "; fi")
custom.func.client_opaque_on(nil) -- start xcompmgr
