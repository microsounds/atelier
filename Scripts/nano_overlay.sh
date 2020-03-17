#!/usr/bin/env sh

## nano_overlay.sh v0.3
## Overlay script that provides additional functionality for GNU nano.
##  -h              Displays this message.

mesg() { echo "${mode:+[$mode] }$@"; }

mode_help() {
	command nano "$@"
	grep '^##' "$0" | sed 's/^## //' 1>&2
	exit
}

## Search and jump to source code definitions using ctags(1).
##  -e <tag> <#>    If a ctags index file exists in the current or a parent
##                  directory, search through it for '<tag>' and open the file
##                  containing it's definition.
##                  If multiple matches are found, specify line number <#>.
##                  * Requires ctags '-n' flag for numeric line numbers.

jump_to() {
	if [ "$(echo "$1" | cut -f3 | cut -c 1-2)" = '/^' ]; then
		mesg 'ctags must be run in '-n' mode for numeric line numbers.'
		exit 1
	fi
	file="$(echo "$1" | cut -f2)"
	line="$(echo "$1" | cut -f3 | egrep -o '[0-9]+')"
	command nano "+$line" "$PWD/$file"
	exit
}

mode_ctags() {
	mode='ctags'
	# find root directory containing ctags index
	# all filenames are relative to this directory
	while [ ! -z "$PWD" ] && [ ! -f "$PWD/tags" ]; do PWD="${PWD%/*}"; done
	if [ -z "$PWD" ]; then
		mesg 'No index found in current or any parent directories up to /.'
		exit 1
	fi
	[ -z "$2" ] && mesg 'Enter a tag query.' && exit 1

	# find matches based on first column
	for f in $(cut -f1 < "$PWD/tags" | grep -i -n "$2" | cut -d ':' -f1); do
		list="$list${f}p;"
	done
	matches="$(sed -n "$list" < "$PWD/tags")"
	[ -z "$matches" ] && mesg "No matches found for $2." && exit 1

	num="$(echo "$matches" | wc -l)"
	if [ "$num" -gt 1 ]; then # multiple matches
		if [ ! -z "$3" ]; then
			[ "$3" -eq "$3" ] 2> /dev/null && # validate
			[ "$3" -le "$num" ] &&
			jump_to "$(echo "$matches" | tail -n "+$3" | head -1)"
		fi
		mesg 'Select a match or be more specific.'
		echo "$matches" | nl | fold -w 80 && exit 1
	fi
	jump_to "$matches"
}

## Open an encrypted file for editing using openssl(1).
##  -f <filename>   Fill in documentation here.

# overlay command line options
if [ ! -z "$1" ] && [ "$(echo "$1" | cut -c 1)" = '-' ]; then
	for f in $(echo "$1" | sed 's/./& /g'); do
		case $f in
			h) mode_help "$@";;
			e) mode_ctags "$@";;
		esac
	done
fi

command nano "$@"
