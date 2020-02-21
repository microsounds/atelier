#!/usr/bin/env sh
## ~/.xinitrc: xinit user configuration

## hardware detection
[ "$(cat /sys/devices/virtual/dmi/id/sys_vendor)" = 'GOOGLE' ] && layout='chromebook'

## set keybindings and keyboard layout
setxkbmap -option 'caps:super'
rm ~/.config/sxhkd/sxhkdrc
for f in default $layout; do
	cat ~/.config/sxhkd/$f >> ~/.config/sxhkd/sxhkdrc
	if [ -f ~/.config/xkb/$f.xkb ]; then
		xkbcomp -merge ~/.config/xkb/$f.xkb $DISPLAY > /dev/null 2>&1
	fi
done

## daemons
sxhkd &
ps -e | fgrep -q "urxvtd" || urxvtd -o -f -q
while xsetroot -name " $(~/Scripts/dwm_status.sh) "; do
	sleep 10
done & # status bar

## run once
xrdb ~/.Xresources
dconf load '/' < ~/.config/dconf/user.conf &
feh --no-fehbg --bg-fill --randomize ~/Pictures/active/* &
~/Scripts/xload.sh vert bottom-right &

exec dwm
