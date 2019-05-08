-- Imports {{{
local awful = require("awful")
local beautiful = require("beautiful")
local util = require("util")
local wibox = require("wibox")

local config = require("custom.config")
local widgets = require("custom.widgets")
local func = require("custom.func")
local modkey = require("custom.config").modkey

local awesome = awesome
local client = client
-- }}}

local structure = {}

-- Helper funcs {{{
local function build(arg)
  local current = {}
  local keys = {} -- keep the keys sorted
  for k, _ in pairs(arg) do table.insert(keys, k) end
  table.sort(keys)

  for _, k in ipairs(keys) do
    local v = arg[k]
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
  { "&quit", function () awesome.quit() end }
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
-- Manage client {{{
function structure.manage_client(c, startup)
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
end
-- }}}
-- Init {{{
function structure.init()
  local tag = awful.tag.add(
    os.getenv("USER"),
    {screen = 1,
     layout = config.property.layout,
     mwfact = config.property.mwfact,
     nmaster = config.property.nmaster,
     ncol = config.property.ncol,
  })
  tag:view_only()

  -- awful.tag.add(
  --   "nil",
  --   {screen = 2,
  --    layout = config.property.layout,
  --    mwfact = config.property.mwfact,
  --    nmaster = config.property.nmaster,
  --    ncol = config.property.ncol,
  --   }
  -- )

  -- attaches main menu to panel
  structure.main_menu = awful.menu(main_menu)
  widgets.launcher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                             menu = structure.main_menu })

  -- creates and attaches taglist widget
  widgets.taglist.buttons = awful.util.table.join(
    awful.button({        }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t) if client.focus then client.focus:move_to_tag(t) end end),
      awful.button({        }, 2, awful.tag.viewtoggle),
      awful.button({ modkey }, 2, function(t) if client.focus then client.focus:toggle_tag(t) end end),
        awful.button({        }, 3, function(t) func.tag_action_menu(t) end),
        awful.button({ modkey }, 3, function(t) t:delete() end),
        awful.button({        }, 4, function(t) awful.tag.viewnext(t.screen) end),
        awful.button({        }, 5, function(t) awful.tag.viewprev(t.screen) end)
  )


  widgets.tasklist = {}
  widgets.tasklist.buttons = awful.util.table.join(

    awful.button({ }, 1, function (c)
        if c == client.focus then
          c.minimized = true
        else
          -- Without this, the following
          -- :isvisible() makes no sense
          c.minimized = false
          if not c:isvisible() and c.first_tag then c.first_tag:view_only() end

          -- This will also un-minimize
          -- the client, if needed
          client.focus = c
          c:raise()
        end
    end),

    awful.button({ }, 2, function (_)
        func.clients_on_tag()
    end),

    awful.button({ modkey }, 2, function (_)
        func.all_clients()
    end),

    awful.button({ }, 3, function (c)
        func.client_action_menu(c)
    end),

    awful.button({ }, 4, function ()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end),

    awful.button({ }, 5, function ()
        awful.client.focus.byidx(1)
        if client.focus then client.focus:raise() end
  end))

  -- Create a wibox for each screen and add it
  awful.screen.connect_for_each_screen(function(s)

      -- Create a promptbox for each screen
      s.mypromptbox = awful.widget.prompt()

      -- Create an imagebox widget which will contains an icon indicating which layout we're using.
      -- We need one layoutbox per screen.
      s.mylayoutbox = awful.widget.layoutbox(s)
      s.mylayoutbox:buttons(
        awful.util.table.join(
          awful.button({ }, 1, function () awful.layout.inc(config.layouts,  1) end),
          awful.button({ }, 3, function () awful.layout.inc(config.layouts, -1) end),
          awful.button({ }, 4, function () awful.layout.inc(config.layouts, -1) end),
          awful.button({ }, 5, function () awful.layout.inc(config.layouts,  1) end),
          nil))

      -- Create a taglist widget
      s.mytaglist = awful.widget.taglist(
        s,
        awful.widget.taglist.filter.all,
        widgets.taglist.buttons)

      -- Create a textbox showing current universal argument
      s.myuniarg = wibox.widget.textbox()

      -- Create a tasklist widget
      s.mytasklist = awful.widget.tasklist(
        s,
        awful.widget.tasklist.filter.currenttags,
        widgets.tasklist.buttons)

      -- Create the wibox
      s.mywibox = awful.wibar({ position = "top", height = "18", screen = s })

      s.mywibox:setup{
        -- left layout
        {
          widgets.launcher,
          s.mytaglist,
          s.myuniarg,
          s.mypromptbox,

          layout = wibox.layout.fixed.horizontal(),
        },

        s.mytasklist,

        {
          wibox.widget.systray(),
          widgets.cpuusage,
          widgets.memusage,
          widgets.bat,
          widgets.playerstatus,

          --widgets.audio_volume,
          widgets.volume,
          widgets.date,
          --widgets.textclock,

          s.mylayoutbox,

          layout = wibox.layout.fixed.horizontal(),
        },

        layout = wibox.layout.align.horizontal(),
      }
  end)

  util.taglist.set_taglist(widgets.taglist)
end
-- }}}


return structure
