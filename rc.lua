local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
require("awful.dbus")
require("awful.remote")

-- local config_path = awful.util.getdir("config")
local config_path = "/home/alex/projects/awesome-wm-config"
package.path = config_path .. "/?.lua;" .. package.path
package.path = config_path .. "/?/init.lua;" .. package.path
package.path = config_path .. "/modules/?.lua;" .. package.path
package.path = config_path .. "/modules/?/init.lua;" .. package.path


local math = require("math")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")
local vicious = require("vicious")

local autostart = require("autostart")
local custom = require('custom')
-- bashets config: https://gitorious.org/bashets/pages/Brief_Introduction
local bashets = require("bashets")
local util = require("util")
local uniarg = require("uniarg")

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
-- Themes define colours, icons, and wallpapers
---[[

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
--]]


local myapp = nil
do
    local function build(arg)
        local current = {}
        local keys = {} -- keep the keys sorted
        for k, v in pairs(arg) do table.insert(keys, k) end
        table.sort(keys)

        for _, k in ipairs(keys) do
            v = arg[k]
            if type(v) == 'table' then
                table.insert(current, {k, build(v)})
            else
                table.insert(current, {v, v})
            end
        end
        return current
    end
    myapp = build(custom.config)
end
--}}

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other custom.config.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.fair,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
}
--[[
local layouts =
{
awful.layout.suit.floating,
awful.layout.suit.tile,
awful.layout.suit.tile.left,
awful.layout.suit.tile.bottom,
awful.layout.suit.tile.top,
awful.layout.suit.fair,
awful.layout.suit.fair.horizontal,
awful.layout.suit.spiral,
awful.layout.suit.spiral.dwindle,
awful.layout.suit.max,
awful.layout.suit.max.fullscreen,
awful.layout.suit.magnifier
}
--]]
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


-- {{{ Menu

-- Create a launcher widget and a main menu
mysystemmenu = {
    --{ "manual", custom.config.terminal .. " -e man awesome" },
    { "&lock", custom.func.system_lock },
    { "&suspend", custom.func.system_suspend },
    { "hi&bernate", custom.func.system_hibernate },
    { "hybri&d sleep", custom.func.system_hybrid_sleep },
    { "&reboot", custom.func.system_reboot },
    { "&power off", custom.func.system_power_off }
}

-- Create a launcher widget and a main menu
myawesomemenu = {
    --{ "manual", custom.config.terminal .. " -e man awesome" },
    { "&edit config", custom.config.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua"  },
    { "&restart", awesome.restart },
    { "&quit", awesome.quit }
}

mymainmenu = awful.menu({
  theme = { width=150, },
  items = {
    { "&system", mysystemmenu },
    { "app &finder", custom.func.app_finder },
    { "&apps", myapp },
    { "&terminal", custom.config.terminal },
    { "a&wesome", myawesomemenu, beautiful.awesome_icon },
    { "&client action", function ()
      custom.func.client_action_menu()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
    { "&tag action", function ()
      custom.func.tag_action_menu()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
    { "clients &on current tag", function ()
      custom.func.clients_on_tag()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
    { "clients on a&ll tags", function ()
      custom.func.all_clients()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
  }
})

custom.widgets.launcher = awful.widget.launcher({ image = beautiful.awesome_icon,
menu = mymainmenu })

-- }}}

-- {{{ Wibox
--custom.widgets.textclock = wibox.widget.textbox()
--bashets.register("date.sh", {widget=custom.widgets.textclock, update_time=1, format="$1 <span fgcolor='red'>$2</span> <small>$3$4</small> <b>$5<small>$6</small></b>"}) -- http://awesome.naquadah.org/wiki/Bashets

-- vicious widgets: http://awesome.naquadah.org/wiki/Vicious

custom.widgets.cpuusage = awful.widget.graph()
custom.widgets.cpuusage:set_width(50)
custom.widgets.cpuusage:set_background_color("#494B4F")
custom.widgets.cpuusage:set_color({
  type = "linear", from = { 0, 0 }, to = { 10,0 },
  stops = { {0, "#FF5656"}, {0.5, "#88A175"}, {1, "#AECF96" }}})
vicious.register(custom.widgets.cpuusage, vicious.widgets.cpu, "$1", 5)
do
    local prog=custom.config.system.taskmanager
    local started=false
    custom.widgets.cpuusage:buttons(awful.util.table.join(
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
vicious.register(custom.widgets.bat0, vicious.widgets.bat, "$2", 61, "BAT0")
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
vicious.register(custom.widgets.date, vicious.widgets.date, "%x %X%Z", 1)
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
    awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
    awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
    awful.button({ }, 4, function () awful.layout.inc(layouts, -1) end),
    awful.button({ }, 5, function () awful.layout.inc(layouts, 1) end),
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

do
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
                        layout = custom.default.property.layout,
                        mwfact = custom.default.property.mwfact,
                        nmaster = custom.default.property.nmaster,
                        ncol = custom.default.property.ncol,
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
            layout = custom.default.property.layout,
            mwfact = custom.default.property.mwfact,
            nmaster = custom.default.property.nmaster,
            ncol = custom.default.property.ncol,
        }
        )
        awful.tag.viewonly(tag)

        awful.tag.add("nil",
        {
            screen = 2,
            layout = custom.default.property.layout,
            mwfact = custom.default.property.mwfact,
            nmaster = custom.default.property.nmaster,
            ncol = custom.default.property.ncol,
        }
        )

    end
end


-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
awful.button({ }, 1, custom.func.all_clients),
awful.button({ }, 2, custom.func.tag_action_menu),
awful.button({ }, 3, function () mymainmenu:toggle() end),
awful.button({ }, 4, awful.tag.viewprev),
awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}
notifylist = {}
-- {{{ Key bindings

local globalkeys = nil
local clientkeys = nil

uniarg:init(custom.widgets.uniarg)

globalkeys = awful.util.table.join(

-- universal arguments

awful.key({ modkey }, "u",
function ()
  uniarg:activate()
  awful.prompt.run({prompt = "Universal Argument: ", text='' .. uniarg.arg, selectall=true},
    custom.widgets.promptbox[mouse.screen].widget,
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
  awful.prompt.run({prompt = "Persistent Universal Argument: ", text='' .. uniarg.arg, selectall=true},
    custom.widgets.promptbox[mouse.screen].widget,
    function (t)
      uniarg.persistent = true
      local n = t:match("%d+")
      if n then
        uniarg:set(n)
      end
      uniarg:update_textbox()
    end)
end),

-- window management

--- restart/quit/info

awful.key({ modkey, "Control" }, "r", awesome.restart),

awful.key({ modkey, "Shift"   }, "q", awesome.quit),

awful.key({ modkey }, "\\", custom.func.systeminfo),

awful.key({modkey}, "F1", custom.func.help),

awful.key({ "Ctrl", "Shift" }, "Escape", function ()
    awful.util.spawn(custom.config.system.taskmanager)
end),

--- Layout

uniarg:key_repeat({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),

uniarg:key_repeat({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

--- multiple screens/multi-head/RANDR

uniarg:key_repeat({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),

uniarg:key_repeat({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),

uniarg:key_repeat({ modkey,           }, "o", awful.client.movetoscreen),

uniarg:key_repeat({ modkey, "Control" }, "o", custom.func.tag_move_screen_next),

uniarg:key_repeat({ modkey, "Shift", "Control" }, "o", custom.func.tag_move_screen_prev),

--- misc

awful.key({modkey}, "F2", function()
    awful.prompt.run(
    {prompt = "Run: "},
    custom.widgets.promptbox[mouse.screen].widget,
    awful.util.spawn, awful.completion.shell,
    awful.util.getdir("cache") .. "/history"
    )
end),

awful.key({modkey}, "r", function()
    awful.prompt.run(
    {prompt = "Run: "},
    custom.widgets.promptbox[mouse.screen].widget,
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
    custom.widgets.promptbox[mouse.screen].widget,
    awful.util.eval, nil,
    awful.util.getdir("cache") .. "/history_eval"
    )
end),

awful.key({ modkey }, "c", function ()
    awful.util.spawn(custom.config.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua" )
end),

awful.key({ modkey, "Shift" }, "/", function() mymainmenu:toggle({keygrabber=true}) end),

awful.key({ modkey, }, ";", function()
  local c = client.focus
  if c then
    custom.func.client_action_menu(c)
  end
end),

awful.key({ modkey, "Shift" }, ";", custom.func.tag_action_menu),

awful.key({ modkey, }, "'", custom.func.clients_on_tag),

awful.key({ modkey, "Ctrl" }, "'", custom.func.clients_on_tag_prompt),

awful.key({ modkey, "Shift" }, "'", custom.func.all_clients),

awful.key({ modkey, "Shift", "Ctrl" }, "'", custom.func.all_clients_prompt),

awful.key({ modkey, }, "x", function() mymainmenu:toggle({keygrabber=true}) end),

awful.key({ modkey, }, "X", function() mymainmenu:toggle({keygrabber=true}) end),

uniarg:key_repeat({ modkey,           }, "Return", function () awful.util.spawn(custom.config.terminal) end),

uniarg:key_repeat({ modkey, "Mod1" }, "Return", function () awful.util.spawn("gksudo " .. custom.config.terminal) end),

-- dynamic tagging

awful.key({ modkey, "Ctrl", "Mod1" }, "t", function ()
  custom.option.tag_persistent_p = not custom.option.tag_persistent_p
  local msg = nil
  if custom.option.tag_persistent_p then
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

awful.key({modkey}, "a", custom.func.tag_add_after),

awful.key({modkey, "Shift"}, "a", custom.func.tag_add_before),

awful.key({modkey, "Shift"}, "d", custom.func.tag_delete),

awful.key({modkey, "Shift"}, "r", custom.func.tag_rename),

--- view

uniarg:key_repeat({modkey,}, "p", custom.func.tag_view_prev),

uniarg:key_repeat({modkey,}, "n", custom.func.tag_view_next),

awful.key({modkey,}, "z", custom.func.tag_last),

awful.key({modkey,}, "g", custom.func.tag_goto),

--- move

uniarg:key_repeat({modkey, "Control"}, "p", custom.func.tag_move_backward),

uniarg:key_repeat({modkey, "Control"}, "n", custom.func.tag_move_forward),

-- client management

--- change focus

uniarg:key_repeat({ modkey,           }, "k", custom.func.client_focus_next),

uniarg:key_repeat({ modkey,           }, "Tab", custom.func.client_focus_next),

uniarg:key_repeat({ modkey,           }, "j", custom.func.client_focus_prev),

uniarg:key_repeat({ modkey, "Shift"   }, "Tab", custom.func.client_focus_prev),

awful.key({ modkey,           }, "y", custom.func.client_focus_urgent),

--- swap order/select master

uniarg:key_repeat({ modkey, "Shift"   }, "j", custom.func.client_swap_prev),

uniarg:key_repeat({ modkey, "Shift"   }, "k", custom.func.client_swap_next),

--- move/copy to tag

uniarg:key_repeat({modkey, "Shift"}, "n", custom.func.client_move_next),

uniarg:key_repeat({modkey, "Shift"}, "p", custom.func.client_move_prev),

awful.key({modkey, "Shift"}, "g", custom.func.client_move_to_tag),

awful.key({modkey, "Control", "Shift"}, "g", custom.func.client_toggle_tag),

--- change space allocation in tile layout

awful.key({ modkey, }, "=", function () awful.tag.setmwfact(0.5) end),

awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05) end),

awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05) end),

uniarg:key_repeat({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster( 1) end),

uniarg:key_repeat({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster(-1) end),

uniarg:key_repeat({ modkey, "Control" }, "l",     function () awful.tag.incncol( 1) end),

uniarg:key_repeat({ modkey, "Control" }, "h",     function () awful.tag.incncol(-1) end),

--- misc

awful.key({ modkey, "Shift" }, "`", custom.func.client_toggle_titlebar),

-- app bindings

--- admin

awful.key({ modkey, }, "`", custom.func.system_lock),

awful.key({ modkey, }, "Home", custom.func.system_lock),

awful.key({ modkey, }, "End", custom.func.system_suspend),

awful.key({ modkey,  "Mod1" }, "Home", custom.func.system_hibernate),

awful.key({ modkey,  "Mod1" }, "End", custom.func.system_hybrid_sleep),

awful.key({ modkey, }, "Insert", custom.func.system_reboot),

awful.key({ modkey, }, "Delete", custom.func.system_power_off),

awful.key({ modkey, }, "/", custom.func.app_finder),

awful.key({ modkey }, "q", function ()
    awful.util.spawn("xfce4-session-logout")
end),

awful.key({ modkey, "Shift" }, "s", function ()
    awful.util.spawn("xfce4-settings-manager")
end),

--- everyday

uniarg:key_repeat({ modkey, "Mod1", }, "l", function ()
    awful.util.spawn(custom.config.system.filemanager)
end),

uniarg:key_repeat({ modkey,  }, "e", function ()
    awful.util.spawn(custom.config.system.filemanager)
end),

uniarg:key_repeat({ modkey,  }, "E", function ()
    awful.util.spawn(custom.config.system.filemanager)
end),

uniarg:key_repeat({ modkey, "Mod1", }, "p", function ()
    awful.util.spawn("putty")
end),

uniarg:key_repeat({ modkey, "Mod1", }, "r", function ()
    awful.util.spawn("remmina")
end),

uniarg:key_repeat({ modkey, }, "i", function ()
    awful.util.spawn(custom.config.editor.primary)
end),

uniarg:key_repeat({ modkey, "Shift" }, "i", function ()
    awful.util.spawn(custom.config.editor.secondary)
end),

uniarg:key_repeat({ modkey, }, "b", function ()
    awful.util.spawn(custom.config.browser.primary)
end),

uniarg:key_repeat({ modkey, "Shift" }, "b", function ()
    awful.util.spawn(custom.config.browser.secondary)
end),

uniarg:key_repeat({ modkey, "Mod1", }, "v", function ()
    awful.util.spawn("virtualbox")
end),

uniarg:key_repeat({modkey, "Shift" }, "\\", function()
    awful.util.spawn("kmag")
end),

--- the rest

uniarg:key_repeat({}, "XF86AudioPrev", function ()
    awful.util.spawn("mpc prev")
end),

uniarg:key_repeat({}, "XF86AudioNext", function ()
    awful.util.spawn("mpc next")
end),

awful.key({}, "XF86AudioPlay", function ()
    awful.util.spawn("mpc toggle")
end),

awful.key({}, "XF86AudioStop", function ()
    awful.util.spawn("mpc stop")
end),

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
--
awful.key({}, "XF86AudioMute", function ()
    awful.util.spawn("amixer sset Master toggle")
end),

awful.key({}, "XF86AudioMicMute", function ()
    awful.util.spawn("amixer sset Mic toggle")
end),

awful.key({}, "XF86ScreenSaver", function ()
    awful.util.spawn("xscreensaver-command -l")
end),

awful.key({}, "XF86WebCam", function ()
    awful.util.spawn("cheese")
end),

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

awful.key({}, "XF86WLAN", function ()
    awful.util.spawn("nm-connection-editor")
end),

awful.key({}, "XF86Display", function ()
    awful.util.spawn("arandr")
end),

awful.key({}, "Print", function ()
    awful.util.spawn("xfce4-screenshooter")
end),

uniarg:key_repeat({}, "XF86Launch1", function ()
    awful.util.spawn(custom.config.terminal)
end),

awful.key({ }, "XF86Sleep", function ()
    awful.util.spawn("systemctl suspend")
end),


awful.key({ modkey }, "XF86Sleep", function ()
    awful.util.spawn("systemctl hibernate")
end),

--- hacks for Thinkpad W530 FN mal-function

uniarg:key_repeat({ modkey }, "F10", function ()
    awful.util.spawn("mpc prev")
end),

awful.key({ modkey }, "F11", function ()
    awful.util.spawn("mpc toggle")
end),

uniarg:key_repeat({ modkey }, "F12", function ()
    awful.util.spawn("mpc next")
end),

uniarg:key_repeat({ modkey, "Control" }, "Left", function ()
    awful.util.spawn("mpc prev")
end),

awful.key({ modkey, "Control" }, "Down", function ()
    awful.util.spawn("mpc toggle")
end),

uniarg:key_repeat({ modkey, "Control" }, "Right", function ()
    awful.util.spawn("mpc next")
end),

awful.key({ modkey, "Control" }, "Up", function ()
    awful.util.spawn("gnome-alsamixer")
end),

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

-- client management

--- operation
clientkeys = awful.util.table.join(

awful.key({ modkey, "Shift"   }, "c", custom.func.client_kill),

awful.key({ "Mod1",   }, "F4", custom.func.client_kill),

awful.key({ modkey, "Shift"   }, "Delete", function (c)
    -- sends SIGKILL to X window currently in focus
    awful.util.spawn("killwindow")
end),

awful.key({ modkey,           }, "f", custom.func.client_fullscreen),

awful.key({ modkey,           }, "m", custom.func.client_maximize),

-- move client to sides, i.e., sidelining

awful.key({ modkey,           }, "Left", custom.func.client_sideline_left),

awful.key({ modkey,           }, "Right", custom.func.client_sideline_right),

awful.key({ modkey,           }, "Up", custom.func.client_sideline_top),

awful.key({ modkey,           }, "Down", custom.func.client_sideline_bottom),

-- extend client sides

uniarg:key_numarg({ modkey, "Mod1"    }, "Left",
custom.func.client_sideline_extend_left,
function (n, c)
custom.func.client_sideline_extend_left(c, n)
end),

uniarg:key_numarg({ modkey, "Mod1"    }, "Right",
custom.func.client_sideline_extend_right,
function (n, c)
custom.func.client_sideline_extend_right(c, n)
end),

uniarg:key_numarg({ modkey, "Mod1"    }, "Up",
custom.func.client_sideline_extend_top,
function (n, c)
custom.func.client_sideline_extend_top(c, n)
end),

uniarg:key_numarg({ modkey, "Mod1"    }, "Down",
custom.func.client_sideline_extend_bottom,
function (n, c)
custom.func.client_sideline_extend_bottom(c, n)
end),

-- shrink client sides

uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Left",
custom.func.client_sideline_shrink_left,
function (n, c)
custom.func.client_sideline_shrink_left(c, n)
end
),

uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Right",
custom.func.client_sideline_shrink_right,
function (n, c)
custom.func.client_sideline_shrink_right(c, n)
end
),

uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Up",
custom.func.client_sideline_shrink_top,
function (n, c)
custom.func.client_sideline_shrink_top(c, n)
end
),

uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Down",
custom.func.client_sideline_shrink_bottom,
function (n, c)
custom.func.client_sideline_shrink_bottom(c, n)
end
),

-- maximize/minimize

awful.key({ modkey, "Shift"   }, "m", custom.func.client_minimize),

awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle),


awful.key({ modkey,           }, "t", custom.func.client_toggle_top),

awful.key({ modkey,           }, "s", custom.func.client_toggle_sticky),

awful.key({ modkey,           }, ",", custom.func.client_maximize_horizontal),

awful.key({ modkey,           }, ".", custom.func.client_maximize_vertical),

awful.key({ modkey,           }, "[", custom.func.client_opaque_less),

awful.key({ modkey,           }, "]", custom.func.client_opaque_more),

awful.key({ modkey, 'Shift'   }, "[", custom.func.client_opaque_off),

awful.key({ modkey, 'Shift'   }, "]", custom.func.client_opaque_on),

awful.key({ modkey, "Control" }, "Return", custom.func.client_swap_with_master),

nil

)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9, plus 0.

for i = 1, 10 do
    local keycode = "#" .. i+9

    globalkeys = awful.util.table.join(globalkeys,

    awful.key({ modkey }, keycode,
    function ()
        local tag
        local tags = awful.tag.gettags(mouse.screen)
        if i <= #tags then
            tag = tags[i]
        else
            local scr = mouse.screen
            awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
            custom.widgets.promptbox[scr].widget,
            function (text)
                if #text>0 then
                    tag = awful.tag.add(text)
                    awful.tag.setscreen(tag, scr)
                    awful.tag.move(#tags+1, tag)
                    awful.tag.viewonly(tag)
                end
            end,
            nil)
        end
        if tag then
            awful.tag.viewonly(tag)
        end
    end),

    awful.key({ modkey, "Control" }, keycode,
    function ()
        local tag
        local tags = awful.tag.gettags(mouse.screen)
        if i <= #tags then
            tag = tags[i]
        else
            local scr = mouse.screen
            awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
            custom.widgets.promptbox[scr].widget,
            function (text)
                if #text>0 then
                    tag = awful.tag.add(text)
                    awful.tag.setscreen(tag, scr)
                    awful.tag.move(#tags+1, tag)
                    awful.tag.viewonly(tag)
                end
            end,
            nil)
        end
        if tag then
            awful.tag.viewtoggle(tag)
        end
    end),

    awful.key({ modkey, "Shift" }, keycode,
    function ()
        local focus = client.focus

        if focus then
            local tag
            local tags = awful.tag.gettags(focus.screen)
            if i <= #tags then
                tag = tags[i]
            else
                local scr = mouse.screen
                awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
                custom.widgets.promptbox[scr].widget,
                function (text)
                    if #text>0 then
                        tag = awful.tag.add(text)
                        awful.tag.setscreen(tag, scr)
                        awful.tag.move(#tags+1, tag)
                        awful.tag.viewonly(tag)
                    end
                end,
                nil)
            end
            if tag then
                awful.client.movetotag(tag)
            end
        end
    end),

    awful.key({ modkey, "Control", "Shift" }, keycode,
    function ()
        local focus = client.focus

        if focus then
            local tag
            local tags = awful.tag.gettags(client.focus.screen)
            if i <= #tags then
                tag = tags[i]
            else
                local scr = mouse.screen
                awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
                custom.widgets.promptbox[scr].widget,
                function (text)
                    if #text>0 then
                        tag = awful.tag.add(text)
                        awful.tag.setscreen(tag, scr)
                        awful.tag.move(#tags+1, tag)
                        awful.tag.viewonly(tag)
                    end
                end,
                nil)
            end
            if tag then
                awful.client.toggletag(tag)
            end
        end
    end),

    nil
    )
end

clientbuttons = awful.util.table.join(
awful.button({ }, 1, function (c)
  if awful.client.focus.filter(c) then
    client.focus = c
    c:raise()
  end
end),
awful.button({ modkey }, 1, awful.mouse.client.move),
awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

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
            keys = clientkeys,
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
