#!/usr/bin/env sh

# adds deb-multimedia repos

TMP="/tmp/$(cat /dev/urandom | tr -cd 'a-z0-9' | head -c 7)"
SOURCE='http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring'
DEB='deb-multimedia-keyring_2016.8.1_all.deb'
APT='/etc/apt/sources.list'

finish() {
	rm -rv "$TMP"
	echo 'Done.'
	exit
}

trap finish 2

echo "$0"
echo "Writing to '$APT'"
sudo tee "$APT" << EOF
deb http://deb.debian.org/debian/ stable main contrib non-free
deb http://deb.debian.org/debian/ stable-updates main contrib non-free
deb http://security.debian.org/debian-security stable/updates main contrib non-free
deb http://www.deb-multimedia.org/ stable main non-free
EOF
mkdir -v "$TMP"
if wget "$SOURCE/$DEB" -O "$TMP/$DEB"; then
	sudo dpkg -i "$TMP/$DEB"
fi
finish

