#!/usr/bin/env sh

## nano_overlay.sh v0.2
## Overlay script that provides additional functionality for GNU nano
## Option           Meaning
##  -e <tag> <#>    Jump into ctags definition if 'tags' file is present in
##                  current or a parent directory.
##                  Requires ctags '-n' flag for numeric line numbers.
##                  * If multiple matches found, specify a number.
##  -h              displays this help message.

# overlay command line options
if [ ! -z "$1" ] && [ "$(echo "$1" | cut -c 1)" = '-' ]; then
	for f in $(echo "$1" | sed 's/./& /g'); do
		case $f in
			e) CTAGS=1;;
			h) grep '^##' "$0" | sed 's/^## //' 1>&2;;
		esac
	done
fi

# ctags definition search
jump_to() {
	if [ "$(echo "$1" | cut -f3 | cut -c 1-2)" = '/^' ]; then
		echo "ctags must be run in '-n' mode for numeric line numbers."
		exit 1
	fi
	file="$(echo "$1" | cut -f2)"
	line="$(echo "$1" | cut -f3 | egrep -o '[0-9]+')"
	command nano "+$line" "$PWD/$file"
	exit
}

if [ ! -z "$CTAGS" ]; then
	# find root directory containing ctags file
	# all filenames are relative to this directory
	while [ ! -z "$PWD" ] && [ ! -f "$PWD/tags" ]; do PWD="${PWD%/*}"; done
	if [ -z "$PWD" ]; then
		echo "No ctags file found in current or any parent directories up to '/'."
		exit 1
	fi
	[ -z "$2" ] && echo "Enter a tag query." && exit 1
	for matches in "$(grep -i "^$2" "$PWD/tags")"; do
		[ -z "$matches" ] && echo "No matches found for '$2'." && exit 1
		for num in $(echo "$matches" | wc -l); do
			if [ "$num" -gt 1 ]; then # multiple matches
				if [ ! -z "$3" ]; then
					[ "$3" -eq "$3" ] 2> /dev/null && # validate
					[ "$3" -le "$num" ] &&
					jump_to "$(echo "$matches" | tail -n "+$3" | head -1)"
				fi
				echo "Select a match or be more specific."
				echo "$matches" | nl | fold -w 80
				exit 1
			fi
		done
		jump_to "$matches"
	done
fi

command nano "$@"
