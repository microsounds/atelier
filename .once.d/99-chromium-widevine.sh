#!/usr/bin/env sh

# chromium_widevine.sh v0.1
# Downloads and extracts proprietary Widevine content decryption module from Google Chrome
# into your existing Chromium installation to enable use of DRM restricted streaming services.

TMP="/tmp/$(cat /dev/urandom | tr -cd 'a-z0-9' | head -c 7)"
SOURCE='https://dl.google.com/linux/direct'
DEB='google-chrome-stable_current_amd64.deb'
DATA='data.tar.xz'
EXTRACT='opt/google/chrome/WidevineCdm'

# default install location
INSTALL='/usr/lib/chromium'

finish() {
	rm -rv "$TMP"
	echo 'Done.'
	exit
}

trap finish 2

echo "$0"
mkdir -v "$TMP"
cd "$TMP"
if wget "$SOURCE/$DEB" -O "$TMP/$DEB"; then
	ar -xv "$DEB" "$DATA"
	tar -xJvf "$DATA"  "./$EXTRACT"
	sudo cp -rv "$TMP/$EXTRACT" "$INSTALL"
fi
finish
