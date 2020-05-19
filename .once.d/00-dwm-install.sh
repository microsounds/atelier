#!/usr/bin/env sh

# automated dwm install script
# configuration should already exist in ~/.config

echo "$0"

for f in dwm-6.2; do
	VERSION="${f#*-}"
	CONFIG="$HOME/.config/${f%-*}"
	ORIGIN="git://git.suckless.org/${f%-*}"
	[ ! -d "$CONFIG" ] && echo "'$CONFIG' doesn't exist." && exit 1

	if cd "$CONFIG" && ! git status 2> /dev/null; then
		git init
		git remote add origin "$ORIGIN"
		git fetch --tags origin master
	fi
	if git checkout -f "$VERSION"; then
		# apply patches
		[ ! -d patches ] || for g in patches/*; do patch < $g; done
		make install PREFIX="$HOME/.local"
	fi
done
