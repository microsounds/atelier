#!/usr/bin/env sh
## ~/.xinitrc: xinit user configuration

# chromebook layout
#xkbcomp ~/Scripts/chromebook.xkb $DISPLAY 2>&1 > /dev/null

# config
xrdb ~/.Xresources

# daemons
sxhkd &
urxvtd -q -o -f

# startup
feh --no-fehbg --bg-tile --randomize ~/Pictures/active/* &
~/Scripts/xload.sh vert bottom-right &
~/Scripts/dwm_status.sh &

exec dwm
