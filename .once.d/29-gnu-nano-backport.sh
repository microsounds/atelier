#!/usr/bin/env sh

# backports latest version of GNU nano

SOURCE='https://www.nano-editor.org/download.php'
TMP="$(mk-tempdir)"

finish() {
	rm -rfv "$TMP"
	echo 'Done.'
	exit
}

echo 'Fetching latest version...'
scrape="$(wget -q -O - "$SOURCE")" || exit 1

trap finish 0 1 2 3 6

mkdir -v "$TMP"
echo "$scrape" | egrep -o '<a href=".*\.tar\.xz">' \
	| head -n 1 | tr '"' '\t' | cut -f2 | while read LATEST; do
	url="${SOURCE%/*}$LATEST"
	version="${LATEST##*/}"
	for f in $(seq 2); do # strip file extension
		 version="${version%.*}"
	done

	nano -V | grep -q "${version#*-}" && \
		echo "$version is already installed." && exit

	echo "Fetching $version from '$url'"
	wget -q -O - "$url" | xz -d | tar -xv -C "$TMP"
	cd "$TMP/$version"
	./configure --prefix=/usr --sysconfdir=/etc --disable-nls
	make && sudo make install-strip
done
