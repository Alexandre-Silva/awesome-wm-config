-- Imports {{{
local awful = require("awful")
local lain = require("lain")
local naughty = require("naughty")
local vicious = require("vicious")
local wibox = require("wibox")
local gears = require("gears")

local config = require("custom.config")

local awesome = awesome
-- }}}

local widgets = {}

--widgets.textclock = wibox.widget.textbox()
--bashets.register("date.sh", {widget=widgets.textclock, update_time=1, format="$1 <span fgcolor='red'>$2</span> <small>$3$4</small> <b>$5<small>$6</small></b>"}) -- http://awesome.naquadah.org/wiki/Bashets

-- vicious widgets: http://awesome.naquadah.org/wiki/Vicious

-- Globals {{{
widgets.uniarg = {}
widgets.wibox = {}
widgets.promptbox = {}
widgets.layoutbox = {}
widgets.taglist = {}
-- }}}

function widgets.add_prog_toggle(widget, prog, mod, button) -- {{{
  mod = mod or {}
  button = button or 1
  local pid = nil
  local ret

  widget:buttons(
    awful.util.table.join(
      widget:buttons(),

      awful.button(
        mod, button,
        function ()
          if pid then
            awful.spawn("kill " .. pid)
            pid = nil

          else
            ret = awesome.spawn(prog, true)
            if type(ret) == "string" then
              naughty.notify({title = "Failure to spawn program.", text = ret, timeout = 10})
              print(ret)

            else
              pid = math.floor(ret) -- convert to int

            end
          end

      end)
  ))
end -- }}}
function widgets.new_cpuusage() -- {{{
  local cpuusage = wibox.widget.graph()
  cpuusage:set_width(50)
  cpuusage:set_background_color("#494B4F")
  cpuusage:set_color({
      type = "linear", from = { 0, 0 }, to = { 10,0 },
      stops = { {0, "#FF5656"}, {0.5, "#88A175"}, {1, "#AECF96" }}
  })

  vicious.register(cpuusage, vicious.widgets.cpu, "$1", 5)

  widgets.add_prog_toggle(cpuusage, config.system.taskmanager)

  return cpuusage
end
-- }}}
function widgets.new_memusage() -- {{{
  local memusage = wibox.widget.textbox()

  vicious.register(memusage, vicious.widgets.mem,
                   "<span fgcolor='yellow'>$1% ($2MB/$3MB)</span>", 3)

  widgets.add_prog_toggle(memusage, config.system.taskmanager)

  return memusage
end -- }}}
function widgets.new_bat() -- {{{
  local lain_bat = lain.widget.bat({
      battery  = "BAT1",
      ac       = "ACAD",
      timeout  = 60,

      settings = function ()
        local bat_now = bat_now
        local widget = widget
        local text=""

        if bat_now.perc ~= "N/A" then
          text = bat_now.perc .. "%"
        end
        if bat_now.ac_status == 1 then
          text = text .. " plug"
        end

        widget:set_markup(text .. " ")
      end
  })


  local icons_dir = awful.util.getdir("config") .. "icons"
  local bat_icon = wibox.widget.imagebox(
    icons_dir .. "/battery.png",
    false
  )

  local bat = wibox.widget {
    layout  = wibox.layout.fixed.horizontal,

    bat_icon,
    lain_bat.widget
  }

  return bat
end -- }}}
function widgets.new_playerstatus() -- {{{
  local playerstatus = wibox.widget.textbox()
  playerstatus:set_ellipsize("end")


  vicious.register(
    playerstatus,
    function (format, warg)
      local player_state = {
        ["{volume}"]   = 0,
        ["{bitrate}"]  = 0,
        ["{elapsed}"]  = 0,
        ["{duration}"] = 0,
        ["{repeat}"]   = false,
        ["{random}"]   = false,
        ["{state}"]    = "N/A",
        ["{Artist}"]   = "N/A",
        ["{Title}"]    = "N/A",
        ["{Album}"]    = "N/A",
        ["{Genre}"]    = "N/A",
        --["{Name}"]   = "N/A",
        --["{file}"]   = "N/A",
      }


      -- Get status from player
      local f = io.popen("playerctl status")
      local state = f:read()
      f:close()

      if state == nil then
        state = "Stop"
      end

      player_state['{state}'] = state


      -- Get music data from player
      local f = io.popen("playerctl metadata")
      for line in f:lines() do
        for player, key, value in string.gmatch(line, "([%w]+) ([%w]+:[%w]+)[%s]+(.*)$") do
          if player == "spotify" then
            if     key == 'xesam:album'   then player_state["{Album}"] = value
            elseif key == 'xesam:artist'  then player_state["{Artist}"] = value
            elseif key == 'xesam:title'   then player_state["{Title}"] = value
            end
          end
        end
      end
      f:close()

      return player_state
    end,

    function (playerwidget, args)
      local text
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
  playerstatus = wibox.container.constraint(playerstatus, "max", 180, nil)

  playerstatus:buttons(
    awful.util.table.join(
      awful.button({ }, 1, function ()
          awful.spawn("playerctl play-pause")
      end),
      awful.button({ }, 2, function ()
          awful.spawn("playerctl previous")
      end),
      awful.button({ }, 3, function ()
          awful.spawn("playerctl next")
      end),
      awful.button({ }, 4, function ()
          awful.spawn("playerctl position 5-")
      end),
      awful.button({ }, 5, function ()
          awful.spawn("playerctl position 5+")
      end)
  ))

  return playerstatus
end --}}}

function widgets.new_volume() -- {{{
  local volume = wibox.widget.textbox()
  vicious.register(volume, vicious.widgets.volume,
                   "<span fgcolor='cyan'>$1%$2</span>", 1, "Master")

  widgets.add_prog_toggle(volume, config.terminal .. " --exec=alsamixer")

  volume:buttons(
    awful.util.table.join(
      volume:buttons(),
      awful.button({ }, 2, function ()
          awful.spawn("amixer sset Mic toggle")
      end),
      awful.button({ }, 3, function ()
          awful.spawn("amixer sset Master toggle")
      end),
      awful.button({ }, 4, function ()
          awful.spawn("amixer sset Master 1%-")
      end),
      awful.button({ }, 5, function ()
          awful.spawn("amixer sset Master 1%+")
      end)
  ))

  return volume
end -- }}}
function widgets.new_date() -- {{{
  local date = wibox.widget.textbox()
  vicious.register(date, vicious.widgets.date, "%d-%m-%y %X", 1)

  widgets.add_prog_toggle(date,"gnome-control-center datetime", {}, 1)
  widgets.add_prog_toggle(date,"gnome-control-center region", {}, 3)
  -- date:buttons(
  --   awful.util.table.join(
  --     awful.button({ }, 1, function ()
  --         if started1 then
  --           awful.spawn("pkill -f '" .. prog1 .. "'")
  --         else
  --           awful.spawn(prog1)
  --         end
  --         started1=not started1
  --     end),
  --     awful.button({ }, 3, function ()
  --         if started2 then
  --           awful.spawn("pkill -f '" .. prog2 .. "'")
  --         else
  --           awful.spawn(prog2)
  --         end
  --         started2=not started2
  --     end)
  -- ))

  return date
end -- }}}

function widgets.init() -- {{{ init
  widgets.cpuusage = widgets.new_cpuusage()
  widgets.memusage = widgets.new_memusage()
  widgets.bat  = widgets.new_bat()
  widgets.playerstatus = widgets.new_playerstatus()
  widgets.volume = widgets.new_volume()
  widgets.date = widgets.new_date()
end -- }}}

return widgets
