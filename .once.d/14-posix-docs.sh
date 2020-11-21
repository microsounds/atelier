#!/usr/bin/env sh

# download POSIX/SUSv4-2018 standards docs

SOURCE='https://pubs.opengroup.org/onlinepubs/9699919799/download'
BINARY='susv4-2018.tar.bz2'
INSTALL="$HOME/.local/share/doc"

mkdir -pv "$INSTALL"
wget -q -O - "$SOURCE/$BINARY" | tar -xvj -C "$INSTALL" || exit 1
