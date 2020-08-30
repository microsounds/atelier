#!/usr/bin/env sh

# forces X servers invoked by non-root users to accept user-provided configs
# Xorg's security model forbids absolute paths to xorg.conf files
# this drops a symlink to ~/.config/xorg to override this behavior

echo "$0"

config="$HOME/.config/xorg"
link="/etc/X11/$(id -u)-override"

# get symlink path, if it exists
[ -L "$link" ] && path="$(ls -l "$link")" && path="${path#*-> }"

if [ "$config" != "$path" ]; then
	sudo rm -rf "$link"
	sudo ln -sfv "$config" "$link"
fi
