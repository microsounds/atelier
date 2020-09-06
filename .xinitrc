#!/usr/bin/env sh
## ~/.xinitrc: xinit multithreaded user config

## keyboard setup
read vendor < /sys/devices/virtual/dmi/id/sys_vendor
unset layout # use alternate keymaps on specific hardware
case $vendor in
	GOOGLE) layout='chromebook';;
esac

## startup daemons tied to this X server invocation
urxvtd -o &
pcmanfm -d &
~/Scripts/wm_status.sh -p & # status bar
for f in decor widgets; do
	xeventbind resolution ~/Scripts/xwin_$f.sh &
done

# sxhkd: generate hotkeys at runtime
{	echo "# !! overwritten by $0 at startup !!" > ~/.config/sxhkd/sxhkdrc
	for f in default $layout; do
		cat ~/.config/sxhkd/$f >> ~/.config/sxhkd/sxhkdrc
	done
} && sxhkd &

## startup items that run once
xset b off &
dconf load '/' < ~/.config/dconf/user.conf &
xrdb ~/.Xresources && {
	for f in decor widgets; do
		~/Scripts/xwin_$f.sh &
	done
} &

# xkb: compile keymaps at runtime
{	setxkbmap -model 'pc105' -layout 'us' -option 'caps:super'
	for f in $layout; do
		if [ -f ~/.config/xkb/$f.xkb ]; then
			xkbcomp -merge ~/.config/xkb/$f.xkb $DISPLAY > /dev/null 2>&1
		fi
	done
} &

exec dwm
