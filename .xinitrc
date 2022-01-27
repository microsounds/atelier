#!/usr/bin/env sh
## ~/.xinitrc: X Window user configuration

## keymap overrides
! is-chromebook || layout='chromebook'
! is-ntc-chip || layout='ntc-chip'

## run-once
# ~/.xrandr: invoke optional display overrides
xrandr-cycle -d &

# mangle xkb keyboard layout at runtime
{	cfg="$HOME/.config/xkb"
	setxkbmap -model 'pc105' -layout 'us' -option 'caps:super'
	for f in $layout; do
		if [ -f "$cfg/$f.xkb" ]; then
			xkbcomp -merge "$cfg/$f.xkb" $DISPLAY 2> /dev/null
		fi
	done
} &

# decorate root window, callback to redraw on display change
xrdb ~/.xresources && {
	for f in widgets decor; do
		"xwin-$f" &
		xeventbind resolution "xwin-$f" &
	done
} &

# GTK2 settings
cpp -P < ~/.config/gtk/gtk2.conf > ~/.gtkrc-2.0 &
ln -sf .config/gtk-3.0/bookmarks ~/.gtk-bookmarks &

# GTK3 settings
dconf load '/' < ~/.config/gtk/gtk3.conf &
{	mkdir -p ~/.config/gtk-3.0
	IFS='
	'
	while read -r dir; do
		prefix='file://'
		[ "${dir%${dir#?}}" = '/' ] || prefix="$prefix$HOME/"
		echo "$prefix$dir ${dir##*/}"
	done <<- EOF
		Downloads
		Pictures/screenshots
		Git
		$XDG_RUNTIME_DIR
		/tmp
		/media
		.local
		.config
	EOF
} > ~/.config/gtk-3.0/bookmarks &

# disable bell in bash prompt
echo 'set bell-style none' > ~/.inputrc &

# prevents dbus applications from hanging on startup
dbus-update-activation-environment --systemd DISPLAY &

## session daemons
# mangle sxhkd config at runtime
{	cfg="$HOME/.config/sxhkd"
	echo "## !! $0: DO NOT EDIT !!" > "$cfg/sxhkdrc"
	for f in default mouse $layout; do
		# sxhkd 0.5.x chokes on excess newlines
		# ignore cpp syntax misuse
		cpp -P < "$cfg/$f" 2> /dev/null | grep . >> "$cfg/sxhkdrc"
	done
} || : && sxhkd &

# restore versioned pcmanfm config at runtime
{	for f in ~/.config/fm/*.conf; do
		file="${f##*/}"; dir="${file%.*}"
		mkdir -p ~/.config/$dir
		cp "$f" ~/.config/$dir/$file
	done
} && pcmanfm -d &

xwin-statusd -qpm | xargs -n 1 xsetroot -name &
urxvtd -o &
lxpolkit &

exec dwm
