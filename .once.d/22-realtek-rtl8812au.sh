#!/usr/bin/env sh

# sideload a DKMS module from Kali Linux for Realtek RTL8812AU-based wifi cards

TMP="/tmp/$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=7 count=1 2> /dev/null)"
SOURCE='https://http.kali.org/kali/pool/contrib/r/realtek-rtl88xxau-dkms'
DEB='realtek-rtl88xxau-dkms_5.6.4.2~20200529-0kali1_all.deb'

finish() {
	rm -rv "$TMP"
	echo 'Done.'
	exit
}

trap finish 0 1 2 3 6

echo "$0"
mkdir -v "$TMP"
if wget "$SOURCE/$DEB" -O "$TMP/$DEB"; then
	sudo dpkg -i "$TMP/$DEB"
fi
