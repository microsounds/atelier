#!/usr/bin/env sh

# dwm install script
# configuration should already exist in ~/.config/dwm
# git refuses to clone into non-empty directories and git-submodule is a mess

CONFIG="$HOME/.config/dwm"
ORIGIN='git://git.suckless.org/dwm'
VERSION='6.2'

echo "$0"
[ ! -d "$CONFIG" ] && echo "'$CONFIG' doesn't exist." && exit 1

if cd "$CONFIG" && ! git status 2> /dev/null; then
	git init
	git remote add origin "$ORIGIN"
	git fetch --tags origin master
fi
if git checkout -f "$VERSION"; then
	for f in patches/*; do # apply patches
		patch < $f;
	done
	make install PREFIX="$HOME/.local" -j $(grep -c '^proc' /proc/cpuinfo)
fi
