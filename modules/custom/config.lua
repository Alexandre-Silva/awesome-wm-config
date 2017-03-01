-- Imports {{{
local awful = require("awful")
-- }}}

local config = {}

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other custom.config.
-- However, you can use another modifier like Mod1, but it may interact with others.
config.modkey = "Mod4"

-- meta configs
config.version = "1.7.18"
config.help_url = "https://github.com/pw4ever/awesome-wm-config/tree/" .. config.version

-- actual configs
config.terminal = os.getenv("TERMCMD") or "xterm"

config.system = {
  taskmanager = "htopl",
  filemanager = "rangerl"
}

config.browser = {
  primary = os.getenv("BROWSER") or "firefox",

  -- if primary is chromium get firefox, and vicev-versa
  secondary = ({chromium="firefox", firefox="chromium"})[primary]
}

config.editor = {
  primary = os.getenv("EDITOR") or "emacs",
  secondary = "vim",
}

-- Table of layouts to cover with awful.layout.inc, order matters.
config.layouts =
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


config.property = {
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

config.compmgr = 'xcompmgr'
config.compmgr_args = '-f -c -s'
config.wallpaper_change_interval = 60


return config
