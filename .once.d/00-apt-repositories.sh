#!/usr/bin/env sh

# defines standard apt repositories
# adds deb-multimedia repos

TMP="/tmp/$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=7 count=1 2> /dev/null)"
SOURCE='http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring'
DEB='deb-multimedia-keyring_2016.8.1_all.deb'
CONF='/etc/apt/sources.list'

finish() {
	rm -rv "$TMP"
	echo 'Done.'
	exit
}

trap finish 0 1 2 3 6

echo "Writing to '$CONF'"
sudo tee "$CONF" <<- EOF
	deb http://deb.debian.org/debian/ stable main contrib non-free
	deb http://deb.debian.org/debian/ stable-updates main contrib non-free
	deb http://security.debian.org/debian-security stable/updates main contrib non-free
	deb http://www.deb-multimedia.org/ stable main non-free
EOF
mkdir -v "$TMP"
if wget "$SOURCE/$DEB" -O "$TMP/$DEB" || exit 1; then
	sudo dpkg -i "$TMP/$DEB"
	for f in update dist-upgrade autopurge clean; do
		sudo apt-get -y $f
	done
fi
