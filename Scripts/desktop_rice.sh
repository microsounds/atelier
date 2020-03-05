#!/usr/bin/env sh

# desktop rice script
# also functions as a callback script on resolution change

xsetroot -gray
feh --no-fehbg --bg-fill --randomize ~/Pictures/active/* &
~/Scripts/xload.sh vert bottom-right &
