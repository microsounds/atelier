#!/usr/bin/env sh

# chromium_widevine.sh v0.2
# Downloads and extracts proprietary Widevine content decryption plugin from Google Chrome
# into your existing Chromium installation to enable use of DRM restricted streaming services.

TMP="/tmp/$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=7 count=1 2> /dev/null)"
SOURCE='https://dl.google.com/linux/direct'
DEB='google-chrome-stable_current_amd64.deb'
DATA='data.tar.xz'
EXTRACT='opt/google/chrome/WidevineCdm'

# default install location
TARGET="/usr/lib/chromium/${EXTRACT##*/}"

finish() {
	rm -rv "$TMP"
	echo 'Done.'
	exit
}

trap finish 0 1 2 3 6

mkdir -v "$TMP"
if wget "$SOURCE/$DEB" -O "$TMP/$DEB" || exit 1; then
	ar -p "$TMP/$DEB" "$DATA" | tar -C "$TMP" -xJv "./$EXTRACT"
	sudo rm -rf "$TARGET"
	sudo mv -v "$TMP/$EXTRACT" "$TARGET"
fi
