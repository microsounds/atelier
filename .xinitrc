#!/usr/bin/env sh
## ~/.xinitrc: xinit user configuration

# hotkeys
sxhkd="default"

## chromebook keyboard layout
if [ "$(cat /sys/devices/virtual/dmi/id/sys_vendor)" = 'GOOGLE' ]; then
	xkbcomp ~/Scripts/chromebook.xkb $DISPLAY > /dev/null 2>&1
	sxhkd="$sxhkd chromebook"
fi

rm ~/.config/sxhkd/sxhkdrc
for f in $sxhkd; do
	cat ~/.config/sxhkd/$f >> ~/.config/sxhkd/sxhkdrc
done

# daemons
sxhkd &
ps -e | fgrep -q "urxvtd" || urxvtd -o -f -q
while xsetroot -name " $(~/Scripts/dwm_status.sh) "; do
	sleep 10
done & # status bar

# run once
xrdb ~/.Xresources
cat ~/.config/dconf/user.conf | dconf load '/' &
feh --no-fehbg --bg-fill --randomize ~/Pictures/active/* &
~/Scripts/xload.sh vert bottom-right &

exec dwm
