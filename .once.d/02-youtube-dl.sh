#!/usr/bin/env sh

# Debian and deb-multimedia are slow to update youtube-dl,
# which pushes updates on a weekly basis

SOURCE='https://yt-dl.org/downloads/latest'
PROG='youtube-dl'

echo "$0"
if wget "$SOURCE/$PROG" -O "$HOME/.local/bin/$PROG"; then
	chmod 755 "$HOME/.local/bin/$PROG"
fi

