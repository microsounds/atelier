#!/usr/bin/env sh
## ~/.xinitrc: xinit user configuration

## keyboard config
setxkbmap -model 'pc105' -layout 'us' -option 'caps:super'

# compile keymaps for specific hardware
read vendor < /sys/devices/virtual/dmi/id/sys_vendor
case $vendor in
	GOOGLE) layout='chromebook';;
esac
for f in $layout; do
	if [ -f ~/.config/xkb/$f.xkb ]; then
		xkbcomp -merge ~/.config/xkb/$f.xkb $DISPLAY > /dev/null 2>&1
	fi
done &

# generate keybindings
rm -f ~/.config/sxhkd/sxhkdrc
for f in default $layout; do
	cat ~/.config/sxhkd/$f >> ~/.config/sxhkd/sxhkdrc
done

## daemons
sxhkd &
urxvtd -o &
xss-lock systemctl suspend &
xeventbind resolution ~/Scripts/xwin_decor.sh &
~/Scripts/wm_status.sh -p & # dwm status bar

## general
xrdb ~/.Xresources
dconf load '/' < ~/.config/dconf/user.conf &
xset b off &
xset s $((3600 * 3)) &
~/Scripts/xwin_decor.sh & # wallpaper/widgets

exec dwm
