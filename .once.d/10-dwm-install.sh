#!/usr/bin/env sh

# automated suckless config and install script
# download from upstream, apply patches and install dwm/dmenu

for f in dwm-6.2 dmenu-5.0; do
	VERSION="${f#*-}"
	CONFIG="$HOME/.config/${f%-*}"
	ORIGIN="git://git.suckless.org/${f%-*}"

	# checkout config directory if it doesn't already exist
	if [ ! -d "$CONFIG" ]; then
		git meta checkout "$CONFIG" || mkdir -v "$CONFIG"
	fi

	# git clone doesn't allow existing files files
	if cd "$CONFIG" && ! git status 2> /dev/null; then
		git init
		git remote add origin "$ORIGIN"
		git fetch --tags origin master || exit 1
	fi
	if git checkout -f "$VERSION"; then
		if [ -d patches ]; then # apply patches
			for g in patches/*.diff; do
				echo "[patch] $g..."
				patch < $g || exit 1
			done
		fi
		make install PREFIX="$HOME/.local" || exit 1
	fi
done
