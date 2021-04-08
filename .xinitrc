#!/usr/bin/env sh
## ~/.xinitrc: X Windows user configuration

## keymap overrides
! is-chromebook || layout='chromebook'

## run-once
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

# GTK config
cpp -P < ~/.config/gtk/gtk2.conf > ~/.gtkrc-2.0 &
dconf load '/' < ~/.config/gtk/gtk3.conf &

# disable PC speaker
xset b off &

## session daemons
# mangle sxhkd config at runtime
{	cfg="$HOME/.config/sxhkd"
	echo "## !! $0: DO NOT EDIT !!" > "$cfg/sxhkdrc"
	for f in default $layout; do
		# sxhkd 0.5.x chokes on excess newlines
		cpp -P < "$cfg/$f" | grep . >> "$cfg/sxhkdrc" 2> /dev/null
	done
} && sxhkd &

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
