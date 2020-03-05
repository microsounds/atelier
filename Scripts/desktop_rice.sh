#!/usr/bin/env sh

# desktop rice script
# also functions as a callback script on resolution change

bg="$(find ~/Pictures/active | shuf | head -1)"

xsetroot -gray # reset wallpaper
feh --no-fehbg --bg-fill "$bg" &
~/Scripts/xload.sh vert bottom-right &
