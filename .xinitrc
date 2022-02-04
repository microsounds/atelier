#!/usr/bin/env sh
## ~/.xinitrc: graphical shell startup configuration

## keymap overrides
! is-chromebook || layout='chromebook'
! is-ntc-chip || layout='ntc-chip'

## runs once
# ~/.xrandr: invokes optional display overrides
xrandr-cycle -d &

# mangle xkb keyboard layout at startup
{	setxkbmap -model 'pc105' -layout 'us' -option 'caps:super'
	for f in $layout; do
		[ -f ~/.config/xkb/$f.xkb ] &&
			xkbcomp -merge ~/.config/xkb/$f.xkb $DISPLAY 2> /dev/null
	done
} &

# GTK2 theming
cpp -P < ~/.config/gtk/gtk2.conf > ~/.gtkrc-2.0 &

# GTK3 file picker config, generate bookmarks
dconf load '/' < ~/.config/gtk/gtk3.conf &
ln -sf .config/gtk-3.0/bookmarks ~/.gtk-bookmarks &
{	mkdir -p ~/.config/gtk-3.0
	IFS='
	'
	while read -r dir; do
		prefix='file://'
		[ "${dir%${dir#?}}" = '/' ] || prefix="$prefix$HOME/"
		echo "$prefix$dir ${dir##*/}"
	done <<- EOF > ~/.config/gtk-3.0/bookmarks
		Downloads
		Pictures/screenshots
		Git
		$XDG_RUNTIME_DIR
		/tmp
		/media
		.local
		.config
	EOF
} &

# disable backspace bell in bash prompt
echo 'set bell-style none' > ~/.inputrc &

# prevents dbus applications from hanging on startup
dbus-update-activation-environment --systemd DISPLAY &

## session daemons
# mangle sxhkd config at runtime
{	echo "## ${0##*/}: DO NOT EDIT"
	for f in default mouse $layout; do
		# sxhkd 0.5.x chokes on excess newlines
		# ignore misuse of cpp syntax
		cpp -P < ~/.config/sxhkd/$f 2> /dev/null | grep .
	done
} > ~/.config/sxhkd/sxhkdrc || : && sxhkd &

# restore versioned pcmanfm config at startup
{	for f in ~/.config/fm/*.conf; do
		file="${f##*/}"; dir="${file%.*}"
		mkdir -p ~/.config/$dir
		cp "$f" ~/.config/$dir/$file
	done
} && pcmanfm -d &

# ~/.xdecor: describes sources for optional background images
# decorate root window, daemonize callback on display change
xrdb ~/.xresources && {
	for f in widgets decor; do
		"xwin-$f" &
		xeventbind resolution "xwin-$f" &
	done
} &

xwin-statusd -qpm | xargs -n 1 xsetroot -name &
urxvtd -o &
lxpolkit &

exec dwm
