#!/usr/bin/env sh

# dotfiles.sh - dotfiles and shell scripts backup
# overwrites every file found in $backup directory
# with identically named file found in home directory
# --
# restore mode: passing '-x' will do this in reverse
# this will also overwrite this script if it's being restored

backup="Git/dotfiles" # relative to home directory
exclude="README.md \.git*" # space delimited pattern list

# colors
INFO=37
WARN=91
OK=92
ACT=93

prefix() { printf '%b ' "\e[${1}m[$2]\e[0m"; }

xclu="$(echo "$exclude" | sed 's/ /|/g')"
filelist="$(find ~ | grep -v "$backup")"
prefix $INFO 'indexing'; echo "$(echo "$filelist" | wc -l) files"

for file in $(find ~/$backup -type f | grep -E -v "$xclu"); do
	base="${file##*/}" # isolate filename
	match="$(echo "$filelist" | grep -E "/$base$")"
	if [ ! -z "$match" ]; then
		prefix $INFO 'match'; echo "$base"
		if [ ! $(echo "$match" | wc -l) -eq 1 ]; then
			prefix $WARN 'error'; echo 'File collision. Skipping.'
			echo "$match" | sed 's/^/-> /g'
		else
			if [ ! -z "$(diff -q "$match" "$file")" ]; then # update on file change
				if [ "$1" != '-x' ]; then
					prefix $ACT 'backup'; cp -v "$match" "$file"
				else
					prefix $ACT 'restore'; cp -v "$file" "$match"
				fi
			else
				prefix $OK 'ok'; echo "$match"
			fi
		fi
	fi
done
