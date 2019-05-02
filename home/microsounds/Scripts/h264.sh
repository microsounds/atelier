#!/usr/bin/env bash

# transcodes HEVC/H.265 matroska containers to H.264
# requires mkvtoolnix and ffmpeg
# intended for transcoding problem video when playing
# back on low-end devices such as android settop boxes
# THIS WILL OVERWRITE THE ORIGINAL

shopt -s nullglob
shopt -s globstar

announce() { echo -e "\e[1;36m${1}\e[0m"; };
prefix() { echo -ne "\e[37m[${1}]\e[0m "; };

for file in **/*.mkv
do
	announce "$file"
	if ! mkvmerge -i "$file" | grep "h.264" > /dev/null; then
		tmp=$(mktemp -u | cut -c 10-)
		id=$(mkvmerge -i "$file" | grep "video" | tr ': ' '\n' | sed -n 3p)
		prefix "extract"; mkvextract tracks "$file" $id:${tmp}_old.mp4 | grep $tmp
		ffmpeg -v quiet -stats -threads $(cat /proc/cpuinfo | grep "processor" | wc -l) \
			-i ${tmp}_old.mp4 \
			-c:v libx264 -preset ultrafast -tune animation ${tmp}_new.mp4
		if [ $? -eq 0 ]; then
			prefix "merge"; mkvmerge -o $tmp.mkv ${tmp}_new.mp4 -D "$file" | grep $tmp.mkv
		fi
		if [ -f $tmp.mkv ]; then
			prefix "overwrite"; mv -v "$tmp.mkv" "$file"
		fi
		rm -rf $tmp*
		sync
	else
		echo "Skipped."
	fi
done
