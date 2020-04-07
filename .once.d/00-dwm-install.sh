#!/usr/bin/env sh
# install dwm

VER='6.2'
SOURCE="$HOME/.config/dwm"

echo "$0"
[ -d "$SOURCE" ] && cd "$SOURCE" || exit 1
if ! git status 2> /dev/null; then
	git init
	git remote add origin 'https://git.suckless.org/dwm'
	git fetch --tags origin master
fi
if git checkout -f "$VER"; then
	for f in patches/*; do # apply patches
		patch < $f;
	done
	make install PREFIX="$HOME/.local" -j $(grep -c '^proc' /proc/cpuinfo)
fi
