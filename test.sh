#!/usr/bin/env bash


# is version3
if $(awesome --version | head --lines 1 | grep v3.5.9 &>/dev/null)  ; then
    AWESOME=~/projects/awesomeWM/install/bin/awesome
fi

AWESOME=${AWESOME:-awesome}

Xephyr -br -ac -noreset -screen 800x600 :2 &
sleep 1
AWESOME_DEBUG='' XDG_CONFIG_HOME=../ DISPLAY=:2 "${AWESOME}" -c ./rc.lua
