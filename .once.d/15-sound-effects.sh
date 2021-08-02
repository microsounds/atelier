#!/usr/bin/env sh

# install certain royalty free sound effects from MusMus
# convert to WAVE files

SOURCE='https://musmus.main.jp/se'
INSTALL="$HOME/.local/share/sfx"

for f in btn cancel other; do
	fname="musmus_${f}_set.zip"
	mkdir -p "$INSTALL/$f"
	wget -O - "$SOURCE/$fname" > "$INSTALL/$fname" || exit 1
	yes y | unzip -d "$INSTALL/$f" "$INSTALL/$fname"
	for g in "$INSTALL/$f/"*.mp3; do
		yes y | ffmpeg -hide_banner -i "$g" \
			-acodec pcm_s16le -ac 1 -ar 16000 "${g%.mp3}.wav" || exit 1
		rm -rf "$g"
	done
	rm -rf "$INSTALL/$fname"
done
