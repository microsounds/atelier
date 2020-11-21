#!/usr/bin/env sh

# automated suckless configuration and install script

for f in dwm-6.2; do
	VERSION="${f#*-}"
	CONFIG="$HOME/.config/${f%-*}"
	ORIGIN="git://git.suckless.org/${f%-*}"

	# checkout config directory if it doesn't already exist
	if [ ! -d "$CONFIG" ]; then
		git meta checkout "$CONFIG" || mkdir -v "$CONFIG"
	fi

	if cd "$CONFIG" && ! git status 2> /dev/null; then
		git init
		git remote add origin "$ORIGIN"
		git fetch --tags origin master || exit 1
	fi
	if git checkout -f "$VERSION"; then
		# apply patches
		[ ! -d patches ] || for g in patches/*; do patch < $g; done
		make install PREFIX="$HOME/.local"
	fi
done
