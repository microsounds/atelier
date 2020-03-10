#!/usr/bin/env sh

# runs startup items that aren't daemons
# set as callback script that executes upon display resolution change

bg="$(find ~/Pictures/active -type f | shuf | head -1)"

xsetroot -solid '#272727' # reset wallpaper
feh --no-fehbg --bg-fill "$bg" &
~/Scripts/xload.sh vert bottom-right &
