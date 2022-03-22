#!/usr/bin/env sh

# install Linux drivers for known Realtek RTL8812AU-based wifi devices
# sideload DKMS module packaged by Kali Linux maintainers
for f in \
	'2357:011e' # TP-Link Archer T2U Nano AC600 Wireless USB Adapter
do lsusb -d "$f" && found=1; done
[ ! -z "$found" ] || exit 0

finish() {
	rm -rv "$TMP"
	echo 'Done.'
	exit
}

trap finish 0 1 2 3 6 15

TMP="$(mk-tempdir)"
mkdir -v "$TMP"

for f in 8814 88xx; do
	SOURCE="https://http.kali.org/kali/pool/contrib/r/realtek-rtl${f}au-dkms"
	DEB="$(wget -q -O - "$SOURCE" | egrep -o '<a href=".*\.deb">' | \
		tr '"' "\t" | cut -f2 | tail -n 1)"

	echo "Fetching '$DEB'..."
	if wget "$SOURCE/$DEB" -O "$TMP/$DEB" || exit 1; then
		sudo dpkg -i "$TMP/$DEB"
	fi
done

