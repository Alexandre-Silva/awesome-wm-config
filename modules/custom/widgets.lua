local awful = require("awful")
local vicious = require("vicious")
local wibox = require("wibox")

local config = require("custom.config")

local widgets = {}

--custom.widgets.textclock = wibox.widget.textbox()
--bashets.register("date.sh", {widget=custom.widgets.textclock, update_time=1, format="$1 <span fgcolor='red'>$2</span> <small>$3$4</small> <b>$5<small>$6</small></b>"}) -- http://awesome.naquadah.org/wiki/Bashets

-- vicious widgets: http://awesome.naquadah.org/wiki/Vicious

-- {{{ Globals
widgets.uniarg = {}
widgets.wibox = {}
widgets.promptbox = {}
widgets.layoutbox = {}
widgets.taglist = {}
-- }}}
-- {{{ Widget Constructers
function widgets.new_cpuusage()
  local cpuusage = awful.widget.graph()
  cpuusage:set_width(50)
  cpuusage:set_background_color("#494B4F")
  cpuusage:set_color({
      type = "linear", from = { 0, 0 }, to = { 10,0 },
      stops = { {0, "#FF5656"}, {0.5, "#88A175"}, {1, "#AECF96" }}
  })
  vicious.register(cpuusage, vicious.widgets.cpu, "$1", 5)

  local prog = config.system.taskmanager
  local started = false
  cpuusage:buttons(
    awful.util.table.join(
      awful.button({ }, 1, function ()
          if started then
            ret = awful.util.spawn("pkill -f '" .. prog .. "'")
            print(ret)
          else
            awful.util.spawn(prog)
          end
          started = not started
      end)
  ))

  return cpuusage
end

-- }}}

return widgets
