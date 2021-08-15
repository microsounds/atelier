#!/usr/bin/env sh

# download POSIX/SUSv4-2018 standards docs

# 2021/08: Downloads inaccessible from the original site, using wayback machine
ARCHIVE='https://web.archive.org/web/20180412190321'

SOURCE='https://pubs.opengroup.org/onlinepubs/9699919799/download'
BINARY='susv4-2018.tgz'
INSTALL="$HOME/.local/share/doc"

mkdir -pv "$INSTALL"
wget -q -O - "$ARCHIVE/$SOURCE/$BINARY" \
	| gzip -d | tar -xv -C "$INSTALL" || exit 1
