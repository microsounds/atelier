#!/usr/bin/env sh

# download POSIX/SUSv4-2018 standards docs

# 2021/08: Downloads inaccessible from the original site, using wayback machine
ARCHIVE='https://web.archive.org/web/20180412190321'

SOURCE='https://pubs.opengroup.org/onlinepubs/9699919799/download'
BINARY='susv4-2018.tgz'
VERSION='POSIX.1-2017'
INSTALL_DIR="$HOME/.local/share/doc"

# version check
mkdir -pv "$INSTALL_DIR"
grep -qr "$VERSION" "$INSTALL_DIR" && \
	echo "$VERSION already installed." && exit 0

wget -q -O - "$ARCHIVE/$SOURCE/$BINARY" \
	| gzip -d | tar -xv -C "$INSTALL_DIR" || exit 1
