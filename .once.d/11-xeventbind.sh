#!/usr/bin/env sh

# install xeventbind utility
# useful for resizing root window decorations on resolution change

TMP="/tmp/$(tr -cd 'a-z0-9' < /dev/urandom | head -c 7)"
REPO='https://github.com/ritave/xeventbind'
BINARY='xeventbind'
INSTALL="$HOME/.local/bin"

finish() {
	rm -rf "$TMP"
	echo 'Done.'
	exit
}

trap finish 0 1 2 3 6

echo "$0"
mkdir -v "$TMP"
if git clone "$REPO" "$TMP"; then
	make -C "$TMP"
	mv -v "$TMP/$BINARY" "$INSTALL"
fi
