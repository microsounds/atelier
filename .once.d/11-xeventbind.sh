#!/usr/bin/env sh

# install xeventbind utility
# useful for resizing root window decorations on resolution change

TMP="/tmp/$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=7 count=1 2> /dev/null)"
REPO='https://github.com/ritave/xeventbind'
BINARY='xeventbind'
INSTALL="$HOME/.local/bin"

finish() {
	rm -rf "$TMP"
	echo 'Done.'
	exit
}

trap finish 0 1 2 3 6

mkdir -v "$TMP"
if git clone "$REPO" "$TMP" || exit 1; then
	make -C "$TMP"
	mv -v "$TMP/$BINARY" "$INSTALL"
fi
