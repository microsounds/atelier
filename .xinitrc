#!/usr/bin/env sh
## ~/.xinitrc: xinit user configuration

# disable hardware beep
xset -b

## XKB hardware overrides
read vendor < /sys/devices/virtual/dmi/id/sys_vendor
case $vendor in
	GOOGLE) layout='chromebook';;
esac

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
urxvtd -o &
~/Scripts/wm_status.sh -p & # status bar

## configuration
xrdb ~/.Xresources
dconf load '/' < ~/.config/dconf/user.conf &
for f in ~/Scripts/xwin_decor.sh; do # callback script
	xeventbind 'resolution' $f &
	$f &
done

exec dwm
