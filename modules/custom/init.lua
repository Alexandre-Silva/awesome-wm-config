local awful = require("awful")

local custom = {}

custom.config = require("custom.config")
custom.orig = {}
custom.func = require("custom.func")
custom.default = require("custom.default")
custom.option = {}
custom.timer = {}
custom.widgets = require("custom.widgets")

custom.option.wallpaper_change_p = true
custom.option.tag_persistent_p = true

return custom
