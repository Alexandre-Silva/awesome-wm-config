-- Imports {{{
local awful = require("awful")
-- }}}

local config = {}
c = config

-- meta configs
config.version = "1.7.18"
config.help_url = "https://github.com/pw4ever/awesome-wm-config/tree/" .. c.version

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

return config
