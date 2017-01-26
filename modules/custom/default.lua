-- Imports {{{
local awful = require("awful")
-- }}}

local default = {}

default.property = {
  layout = awful.layout.suit.floating,
  mwfact = 0.5,
  nmaster = 1,
  ncol = 1,
  min_opacity = 0.4,
  max_opacity = 1,
  default_naughty_opacity = 1,
  low_naughty_opacity = 0.90,
  normal_naughty_opacity = 0.95,
  critical_naughty_opacity = 1,
  minimal_client_width = 50,
  minimal_client_height = 50,
}

default.compmgr = 'xcompmgr'
default.compmgr_args = '-f -c -s'
default.wallpaper_change_interval = 60

return default
