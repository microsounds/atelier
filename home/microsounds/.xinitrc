#!/usr/bin/env sh
## ~/.xinitrc: xinit user configuration

# config
xrdb ~/.Xresources

# daemons
urxvtd -q -o -f

# startup
feh --no-fehbg --bg-tile --randomize ~/Pictures/active/* &
~/Scripts/xload.sh &
~/Scripts/dwm_status.sh &

exec dwm
