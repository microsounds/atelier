#!/usr/bin/env sh
## ~/.xinitrc: X Windows user configuration

## keyboard setup
read vendor < /sys/devices/virtual/dmi/id/sys_vendor
unset layout # use alternate keymaps on specific hardware
case $vendor in
	GOOGLE) layout='chromebook';;
esac

## daemons tied to this X server instance
urxvtd -o &
~/Scripts/wm_status.sh -pm & # status bar

# mangle sxhkd config at runtime
{	echo "# !! overwritten by $0 at startup !!" > ~/.config/sxhkd/sxhkdrc
	for f in default $layout; do
		cat ~/.config/sxhkd/$f >> ~/.config/sxhkd/sxhkdrc
	done
} && sxhkd &

# reload wallpaper/widgets upon display resolution change
for f in decor widgets; do
	xeventbind resolution ~/Scripts/xwin_$f.sh &
done

## startup items that run once
xset b off &
dconf load '/' < ~/.config/dconf/user.conf &
xrdb ~/.xresources && {
	for f in decor widgets; do
		~/Scripts/xwin_$f.sh &
	done
} &

# mangle xkb keyboard layout at runtime
{	setxkbmap -model 'pc105' -layout 'us' -option 'caps:super'
	for f in $layout; do
		if [ -f ~/.config/xkb/$f.xkb ]; then
			xkbcomp -merge ~/.config/xkb/$f.xkb $DISPLAY > /dev/null 2>&1
		fi
	done
} &

exec dwm
