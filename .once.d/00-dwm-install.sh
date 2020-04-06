#!/usr/bin/env sh
# install dwm
# force inclusion of user-specific headers

VER='6.2'

echo "$0"
cd ~/.config/dwm
if ! git status; then
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
