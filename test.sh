#!/usr/bin/env bash

Xephyr -br -ac -noreset -screen 800x600 :2 &
sleep 1
DISPLAY=:2 awesome -c ~/projects/awesome-wm-config/rc.lua
