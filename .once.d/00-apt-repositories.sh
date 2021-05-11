#!/usr/bin/env sh

# defines standard apt repositories
# adds deb-multimedia repos

SOURCE='https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring'
DEB='deb-multimedia-keyring_2016.8.1_all.deb'
CONF='/etc/apt/sources.list'
TMP="$(mk-tempdir)"

finish() {
	rm -rv "$TMP"
	echo 'Done.'
	exit
}

trap finish 0 1 2 3 6

echo "Writing to '$CONF'"
sudo tee "$CONF" <<- EOF
	deb https://deb.debian.org/debian bullseye main contrib non-free
	deb https://deb.debian.org/debian bullseye-updates main contrib non-free
	deb https://security.debian.org/debian-security bullseye-security main contrib non-free
	deb https://www.deb-multimedia.org bullseye main non-free
EOF

mkdir -v "$TMP"
if wget "$SOURCE/$DEB" -O "$TMP/$DEB" || exit 1; then
	sudo dpkg -i "$TMP/$DEB"
	for f in update dist-upgrade autopurge clean; do
		sudo apt-get -y $f
	done
fi
