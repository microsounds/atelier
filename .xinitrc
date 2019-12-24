#!/usr/bin/env sh
## ~/.xinitrc: xinit user configuration

# sxhkd defaults
cfg=~/.config/sxhkd # prefix
layout="$cfg/default"

# chromebook keyboard hack
if [ "$(cat /sys/devices/virtual/dmi/id/sys_vendor)" = 'GOOGLE' ]; then
	xkbcomp ~/Scripts/chromebook.xkb $DISPLAY > /dev/null 2>&1
	layout="$layout $cfg/chromebook"
fi

# config
xrdb ~/.Xresources

# daemons
sxhkd -c $layout &
urxvtd -q -o -f
while true; do # status bar
	xsetroot -name " $(~/Scripts/dwm_status.sh) "
	sleep 10
done &

# run once
feh --no-fehbg --bg-fill --randomize ~/Pictures/active/* &
~/Scripts/xload.sh vert bottom-right &

exec dwm
