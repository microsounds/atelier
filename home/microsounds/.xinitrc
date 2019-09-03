#!/usr/bin/env sh
## ~/.xinitrc: xinit user configuration

xrdb ~/.Xresources
feh --no-fehbg --bg-tile --randomize ~/Pictures/active/* &
~/Scripts/xload.sh &
~/Scripts/dwm_status.sh &

exec dwm
