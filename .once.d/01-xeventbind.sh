#!/usr/bin/env sh

TMP="/tmp/$(tr -cd 'a-z0-9' < /dev/urandom | head -c 7)"
REPO='https://github.com/ritave/xeventbind'
BINARY='xeventbind'
INSTALL="$HOME/.local/bin"

finish() {
	rm -rf "$TMP"
	echo 'Done.'
	exit
}

echo "$0"
mkdir -v "$TMP"
trap finish 1 2 3 6
if git clone "$REPO" "$TMP"; then
	make -C "$TMP"
	mv -v "$TMP/$BINARY" "$INSTALL"
fi
finish
