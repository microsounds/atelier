#!/usr/bin/env sh

# forces X servers invoked by non-root users to accept user-provided configs
# not located in one of several "blessed" directories such as /etc/X11
# this drops a symlink in /etc/X11 to ~/.config/xorg to override this behavior

echo "$0"

config="$HOME/.config/xorg"
link="/etc/X11/$(id -u)-override"

# get symlink path, if it exists
[ -L "$link" ] && path="$(ls -l "$link")" && path="${path#*-> }"

if [ "$config" != "$path" ]; then
	sudo rm -rf "$link"
	sudo ln -sfv "$config" "$link"
fi
