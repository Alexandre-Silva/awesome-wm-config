#!/usr/bin/env bash

Xephyr -br -ac -noreset -screen 800x600 :2 &
sleep 1
XDG_CONFIG_HOME=~/projects DISPLAY=:2 awesome -c ~/projects/awesome/rc.lua
