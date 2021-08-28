#!/usr/bin/env sh

# automated sunvox install script

SOURCE='https://www.warmplace.ru/soft/sunvox'
PROGRAM='sunvox'
ARCH='linux_x86_64'
INSTALL="$HOME/.local"
TMP="$(mk-tempdir)"

finish() {
	rm -rv "$TMP"
	echo 'Done.'
	exit
}

trap finish 0 1 2 3 6

# fetch version information
scrape="$(wget -q -O - "$SOURCE")" || exit 1

mkdir -v "$TMP"
echo "$scrape" | grep 'title_version' \
     | egrep -o 'v([0-9.])+[a-z]?' | while read VERSION; do
	# download and unzip
	FILENAME="$PROGRAM-${VERSION##v}.zip"
	wget "$SOURCE/$FILENAME" -O "$TMP/$FILENAME"
	unzip "$TMP/$FILENAME" -d "$TMP"

	# purge previous installation
	OPT="$INSTALL/opt"
	rm -rf "$OPT/$PROGRAM"
	mkdir -p "$OPT/$PROGRAM"
	mv "$TMP/$PROGRAM" "$OPT/$PROGRAM"

	# generate relative pathname for symlink
	TARGET="$(find "$OPT/$PROGRAM" | grep "$ARCH/${PROGRAM}$")"
	ln -sfv  "..${TARGET#"$INSTALL"}" "$INSTALL/bin"
done
