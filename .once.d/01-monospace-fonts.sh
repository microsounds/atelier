#!/usr/bin/env sh

# archive of monospace fonts
SOURCE='https://github.com/chrissimpkins/codeface/releases/download/font-collection'
FILE='codeface-fonts.tar.xz'
for f in verily-serif-mono; do # extract only selected fonts
	SELECTED="$SELECTED fonts/$f"
done

echo "$0"
wget -O - "$SOURCE/$FILE" | tar -xvJ -C "$HOME/.local/share" $SELECTED
fc-cache -fv
