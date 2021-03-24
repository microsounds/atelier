#!/usr/bin/env sh

# automated sunvox install script

TMP="/tmp/$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=7 count=1 2> /dev/null)"
SOURCE='https://www.warmplace.ru/soft/sunvox'
PROGRAM='sunvox'
ARCH='linux_x86_64'
INSTALL="$HOME/.local"

# network connectivity
ping -c 1 '8.8.8.8' > /dev/null || exit 1

finish() {
	rm -rv "$TMP"
	echo 'Done.'
	exit
}

trap finish 0 1 2 3 6

mkdir -v "$TMP"
# fetch version information
wget -q -O - "$SOURCE" | grep 'title_version' \
     | egrep -o 'v([0-9.])+[a-z]?' | while read VERSION; do
	# download and unzip
	FILENAME="$PROGRAM-${VERSION##v}.zip"
	wget "$SOURCE/$FILENAME" -O "$TMP/$FILENAME"
	unzip "$TMP/$FILENAME" -d "$TMP"

	# purge previous installation
	SHARE="$INSTALL/share"
	rm -rf "$SHARE/$PROGRAM"
	mv "$TMP/$PROGRAM" "$SHARE"
	TARGET="$(find "$SHARE/$PROGRAM" | grep "$ARCH/${PROGRAM}$")"
	ln -sfv  "$TARGET" "$INSTALL/bin"
done
