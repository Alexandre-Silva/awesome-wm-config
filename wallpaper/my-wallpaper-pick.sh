#!/bin/bash

# if [ -d ~/.cache/wallpapers ]; then
    # cd ~/.cache/wallpapers;
# fi

# find . -type f \( -name '*.jpg' -o -name '*.png' \) -print0 | shuf -n1 -z | xargs -0 feh --bg-fill

d1=~/.cache/wallpapers
d2=./

[ -d $d2 ] && d=$d2
[ -d $d1 ] && d=$d1

for i in $(seq 0 2); do
    if ! nitrogen $d --random --set-zoom --head=$i ; then
        break;
    fi
done
