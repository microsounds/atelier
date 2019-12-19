#!/usr/bin/env sh
## ~/.xinitrc: xinit user configuration

# sxhkd defaults
cfg=~/.config/sxhkd # prefix
layout="$cfg/default"

# chromebook keyboard hack
if [ "$(cat /sys/devices/virtual/dmi/id/sys_vendor)" = 'GOOGLE' ]; then
	xkbcomp ~/Scripts/chromebook.xkb $DISPLAY
	layout="$layout $cfg/chromebook"
fi

# config
xrdb ~/.Xresources

# daemons
sxhkd -c $layout &
urxvtd -q -o -f

# startup
feh --no-fehbg --bg-fill --randomize ~/Pictures/active/* &
~/Scripts/xload.sh vert bottom-right &
~/Scripts/dwm_status.sh &

exec dwm
