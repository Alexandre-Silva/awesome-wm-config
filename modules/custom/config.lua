local awful = require("awful")

local config = {}
c = config

-- meta configs
c.version = "1.7.18"
c.help_url = "https://github.com/pw4ever/awesome-wm-config/tree/" .. c.version

-- actual configs
c.terminal = os.getenv("TERMCMD") or "xterm"

c.system = {
  taskmanager = "htopl",
  filemanager = "rangerl"
}

c.browser = {
  primary = os.getenv("BROWSER") or "firefox",

  -- if primary is chromium get firefox, and vicev-versa
  secondary = ({chromium="firefox", firefox="chromium"})[primary]
}

c.editor = {
  primary = os.getenv("EDITOR") or "emacs",
  secondary = "vim",
}

-- Table of layouts to cover with awful.layout.inc, order matters.
c.layouts =
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
