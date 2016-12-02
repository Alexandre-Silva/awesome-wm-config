local awful = require("awful")
local vicious = require("vicious")
local wibox = require("wibox")
local naughty = require("naughty")

local config = require("custom.config")

local widgets = {}

--widgets.textclock = wibox.widget.textbox()
--bashets.register("date.sh", {widget=widgets.textclock, update_time=1, format="$1 <span fgcolor='red'>$2</span> <small>$3$4</small> <b>$5<small>$6</small></b>"}) -- http://awesome.naquadah.org/wiki/Bashets

-- vicious widgets: http://awesome.naquadah.org/wiki/Vicious

-- {{{ Globals
widgets.uniarg = {}
widgets.wibox = {}
widgets.promptbox = {}
widgets.layoutbox = {}
widgets.taglist = {}
-- }}}

function widgets.add_prog_toggle(widget, prog, _mod, _button) -- {{{
  if not _mod or not _button then
    mod = {}
    button = 1
  end

  local pid = nil

  widget:buttons(
    awful.util.table.join(
      widget:buttons(),

      awful.button(
        mod, button,
        function ()
          if pid then
            awful.util.spawn("kill " .. pid)
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
  local cpuusage = awful.widget.graph()
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
  memusage = wibox.widget.textbox()

  vicious.register(memusage, vicious.widgets.mem,
                   "<span fgcolor='yellow'>$1% ($2MB/$3MB)</span>", 3)

  widgets.add_prog_toggle(memusage, config.system.taskmanager)

  return memusage
end -- }}}
function widgets.new_bat0() -- {{{
  bat0 = awful.widget.progressbar()
  bat0:set_width(8)
  bat0:set_height(10)
  bat0:set_vertical(true)
  bat0:set_background_color("#494B4F")
  bat0:set_border_color(nil)
  bat0:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 10 },
                   stops = { { 0, "#AECF96" }, { 0.5, "#88A175" }, { 1, "#FF5656" }}
  })

  vicious.register(bat0, vicious.widgets.bat, "$2", 61, "BAT1")

  widgets.add_prog_toggle(bat0, "gnome-control-center power")

  return bat0
end -- }}}
function widgets.new_mpdstatus() -- {{{
  mpdstatus = wibox.widget.textbox()
  mpdstatus:set_ellipsize("end")

  vicious.register(
    mpdstatus, vicious.widgets.mpd,
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
  mpdstatus = wibox.layout.constraint(mpdstatus, "max", 180, nil)

  mpdstatus:buttons(
    awful.util.table.join(
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

  return mpdstatus
end --}}}
function widgets.new_volume() -- {{{
  volume = wibox.widget.textbox()
  vicious.register(volume, vicious.widgets.volume,
                   "<span fgcolor='cyan'>$1%$2</span>", 1, "Master")

  widgets.add_prog_toggle(volume, config.terminal .. " --exec=alsamixer")

  volume:buttons(
    awful.util.table.join(
      volume:buttons(),
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

  return volume
end -- }}}
function widgets.new_date() -- {{{
  date = wibox.widget.textbox()
  vicious.register(date, vicious.widgets.date, "%d-%m-%y %X", 1)

  local prog1="gnome-control-center datetime"
  local started1=false
  local prog2="gnome-control-center region"
  local started2=false

  widgets.add_prog_toggle(date,"gnome-control-center datetime", {}, 1)
  widgets.add_prog_toggle(date,"gnome-control-center region", {}, 3)
  -- date:buttons(
  --   awful.util.table.join(
  --     awful.button({ }, 1, function ()
  --         if started1 then
  --           awful.util.spawn("pkill -f '" .. prog1 .. "'")
  --         else
  --           awful.util.spawn(prog1)
  --         end
  --         started1=not started1
  --     end),
  --     awful.button({ }, 3, function ()
  --         if started2 then
  --           awful.util.spawn("pkill -f '" .. prog2 .. "'")
  --         else
  --           awful.util.spawn(prog2)
  --         end
  --         started2=not started2
  --     end)
  -- ))

  return date
end -- }}}

function widgets.init() -- {{{ init
  widgets.cpuusage = widgets.new_cpuusage()
  widgets.memusage = widgets.new_memusage()
  widgets.bat0  = widgets.new_bat0()
  widgets.mpdstatus = widgets.new_mpdstatus()
  widgets.volume = widgets.new_volume()
  widgets.date = widgets.new_date()
end -- }}}

return widgets
