#!/usr/bin/env sh
## ~/.xinitrc: X Windows user configuration

## keymap overrides
read vendor < /sys/devices/virtual/dmi/id/sys_vendor
unset layout
case $vendor in
	GOOGLE) layout='chromebook';;
esac

## run-once
# mangle xkb keyboard layout at runtime
{	setxkbmap -model 'pc105' -layout 'us' -option 'caps:super'
	for f in $layout; do
		if [ -f ~/.config/xkb/$f.xkb ]; then
			xkbcomp -merge ~/.config/xkb/$f.xkb $DISPLAY > /dev/null 2>&1
		fi
	done
} &

# decorate root window, callback to redraw on display change
xrdb ~/.xresources && {
	for f in ~/Scripts/xwin_*; do
		"$f" &
		xeventbind resolution "$f" &
	done
} &

dconf load '/' < ~/.config/dconf/user.conf &
xset b off &

## session daemons
# mangle sxhkd config at runtime
{	echo "# !! overwritten by $0 at startup !!" > ~/.config/sxhkd/sxhkdrc
	for f in default $layout; do
		cat ~/.config/sxhkd/$f >> ~/.config/sxhkd/sxhkdrc
	done
} && sxhkd &

~/Scripts/wm_status.sh -pm & # status bar
urxvtd -o &
pcmanfm -d &
lxpolkit &

exec dwm
