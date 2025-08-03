#!/usr/bin/env sh
## ~/.xinitrc: graphical shell startup configuration

# persist cursor size on multi-monitor setups
export XCURSOR_SIZE=16

## keymap overrides
! is-ntc-chip || layout='ntc-chip'

## runs once
# ~/.xrandr: invokes optional display overrides
xrandr-cycle -d &

# mangle xkb keyboard layout shortly after startup
# keyd doesn't rebind modifiers reliably
{	setxkbmap -model 'pc105' -layout 'us' -option 'caps:super'
	for f in ~/.config/xkb/$layout.xkb; do
		[ -f "$f" ] && sleep 1 && xkbcomp -merge "$f" $DISPLAY 2> /dev/null
	done
} &

## GTK2/3 config
# GTK3 file picker config, generate bookmarks
dconf load '/' < ~/.config/gtk/gtk3-dconf.conf &
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

	# mangle GTK2/3 theming
	cpp -P < ~/.config/gtk/gtk2.conf > ~/.gtkrc-2.0
	cpp -P < ~/.config/gtk/gtk3.conf > ~/.config/gtk-3.0/settings.ini
	cpp -P < ~/.config/gtk/gtk3.css > ~/.config/gtk-3.0/gtk.css
} &

# disable backspace bell in bash prompt
echo 'set bell-style none' > ~/.inputrc &

## session daemons
# dbus: prevents dbus-specific applications from hanging at startup
# stupid hack: find existing dbus-daemon session handled by systemd
dbus_pid=$(pgrep -u "$(whoami)" dbus-daemon | head -n 1)
export $(tr '\0' '\n' \
	< /proc/$dbus_pid/environ | fgrep 'DBUS_SESSION_BUS_ADDRESS')

# fcitx5: IME integration for kana input
export GTK_IM_MODULE='fcitx'
export QT_IM_MODULE='fcitx'
export XMODIFIERS='@im=fcitx'
fcitx5 &

# sxhkd: mangle config at runtime
{	echo "## ${0##*/}: DO NOT EDIT"
	for f in default mouse $layout; do
		# sxhkd 0.5.x chokes on excess newlines
		# ignore misuse of cpp syntax
		cpp -P < ~/.config/sxhkd/$f 2> /dev/null | grep .
	done
} > ~/.config/sxhkd/sxhkdrc || : && sxhkd &

# pcmanfm: restore versioned config at startup
{	for f in libfm pcmanfm; do
		mkdir -p ~/.config/$f
		cp ~/.config/fm/$f.conf ~/.config/$f/$f.conf
	done
	# restore desktop config to every active screen
	for f in $(seq 0 $(($(xrandr -q | fgrep -c '*') - 1))); do
		cpp -P -D HOME="$HOME" < ~/.config/fm/desktop.conf \
			> ~/.config/pcmanfm/default/desktop-items-$f.conf
	done
} && pcmanfm -d --desktop &

# ~/.xdecor: describes sources for optional background images
# decorate root window, daemonize callback on display change
xrdb ~/.xresources && {
	for f in decor widgets; do
		"xwin-$f" &
		xeventbind resolution "xwin-$f" &
	done
} &

xwin-statusd -qpm | xargs -n 1 xsetroot -name &
urxvtd -o &
lxpolkit &

exec dwm
