local awful = require("awful")
local beautiful = require("beautiful")

local config = require("custom.config")
local widgets = require("custom.widgets")
local func = require("custom.func")

local structure = {}

-- helper funcs {{{
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
-- }}}

-- Menus {{{
local apps_menu = build({system=config.system,
                         terminal=config.terminal,
                         browser=config.browser,
                         editor=config.editor,
})

-- Create a launcher widget and a main menu
local system_menu = {
  --{ "manual", config.terminal .. " -e man awesome" },
  { "&lock", func.system_lock },
  { "&suspend", func.system_suspend },
  { "hi&bernate", func.system_hibernate },
  { "hybri&d sleep", func.system_hybrid_sleep },
  { "&reboot", func.system_reboot },
  { "&power off", func.system_power_off }
}

-- Create a launcher widget and a main menu
local awesome_menu = {
  --{ "manual", config.terminal .. " -e man awesome" },
  { "&edit config", config.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua"  },
  { "&restart", awesome.restart },
  { "&quit", awesome.quit }
}

local main_menu = {
  theme = { width=150, },
  items = {
    { "&system", system_menu },
    { "app &finder", func.app_finder },
    { "&apps", apps_menu },
    { "&terminal", config.terminal },
    { "a&wesome", awesome_menu, beautiful.awesome_icon },
    { "&client action",
      function () func.client_action_menu() end,
      beautiful.awesome_icon },
    { "&tag action",
      function () func.tag_action_menu() end,
      beautiful.awesome_icon },
    { "clients &on current tag",
      function () func.clients_on_tag() end,
      beautiful.awesome_icon },
    { "clients on a&ll tags",
      function () func.all_clients()  end,
      beautiful.awesome_icon },
  }
}
-- }}}


-- attaches widgets to panel
function structure.init()
  structure.main_menu = awful.menu(main_menu)

  widgets.launcher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                             menu = main_menu })
end

-- }}}

return structure
