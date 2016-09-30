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

return config
