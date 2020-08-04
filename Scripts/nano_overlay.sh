#!/usr/bin/env sh

## nano_overlay.sh v0.8 — interactive external overlay for GNU nano
## (c) 2020 microsounds <https://github.com/microsounds>, GPLv3+
##  -h, --help      Displays this message.

# use nano overlay instead of standard nano for interactive features
ACTUAL_EDITOR='/usr/bin/nano'
EDITOR="$0"

mesg_st() { printf '%s%s' "${mode:+[$mode] }" "$1"; } # for prompts
mesg() { mesg_st "$1"; printf '\n'; }
quit() { mesg "$1, exiting." 1>&2; exit 1; }
announce() { echo "$@" 1>&2; "$@"; }

derive_parent() {
	# return parent dir if path has
	# ../relative/sub/dirs or is absolute path
	# return '.' if path is in the current dir
	case "$1" in
		*/*)
			path="${1%/*}"
			path="${path:-/}";; # if nothing left, assume '/'
	esac
	echo "${path:-.}"
}

mode_help() {
	$ACTUAL_EDITOR -h
	grep '^##' "$0" | sed 's/^## //'
}

## Search and jump to source code definitions provided by POSIX ctags(1).
##  -e <tag> <#>    If a ctags index file exists in the current or a parent
##  or --ctags      directory, search through it for '<tag>' and open the file
##                  containing it's definition.
##                  If multiple matches are found, specify line number <#>
##                  or 'all' to open all matches at once.

ex_parser() {
	# format: {tag}\t{filename}\t{ex command or line no}{;" extended}
	# follow ex editor commands and rewrite as line numbers
	IFS='	'; while read -r tag file addr; do
		# return 1 if line is malformed
		for f in tag file addr; do
			eval "[ ! -z \"\${$f}\" ]" || return 1
		done
		# absolute filename?
		[ "${file%${file#?}}" = '/' ] || file="$PWD/$file"
		printf '%s\t%s\t' "$tag" "$file"

		# if addr is not numeric, parse as ex command
		case "$addr" in [!0-9]*)
			# extract delimited text
			# strip delimiters, regex anchors and slash escapes
			de="${addr%"${addr#?}"}"
			addr="${addr#*"$de"}"; addr="${addr%"$de"*}"
			[ "${addr%"${addr#?}"}" = '^' ] && addr="${addr#^}"
			[ "${addr#"${addr%?}"}" = '$' ] && addr="${addr%$}"
			addr="$(echo "$addr" | sed 's,\\/,/,g;s,\\\\,\\,g')"
			# return 2 if command is outdated
			addr="$(fgrep -n "$addr" < "$file")" || return 2;;
		esac
		echo "${addr%%[!0-9]*}"
	done < /dev/stdin
}

mode_ctags() {
	mode='ctags'
	# find root directory containing ctags index
	# prefixes all relative filenames found
	while [ ! -z "$PWD" ] && [ ! -f "$PWD/tags" ]; do PWD="${PWD%/*}"; done
	[ ! -z "$PWD" ] ||
		quit 'No index found in this or any parent directories up to /'

	# validate index and get version
	ver="$(fgrep '!_TAG_FILE_FORMAT' < "$PWD/tags" | cut -f2)"
	case "$ver" in 1 | 2);; *) quit 'Index file is invalid'; esac

	[ ! -z "$1" ] || quit 'No tag query given'

	# session persistence
	unset matches
	backup="${XDG_RUNTIME_DIR:-/tmp}/.${0##*/}-$mode"
	if [ -f "${backup}-cached" ]; then
		read -r prev_query < "${backup}-query"
		read -r prev_hash < "${backup}-hash"
		[ "$prev_query" = "$1" ] &&
		[ "$prev_hash" = "$(md5sum < "$PWD/tags")" ] &&
		matches="$(cat "${backup}-cached")"
	fi

	# discarding previous session
	if [ -z "$matches" ]; then
		# cherry-pick matching lines based on first column
		# case insensitive substring search up to first literal tab
		matches="$(grep -v '^!_TAG_' < "$PWD/tags" | \
			egrep -i "^\\w*${1}\\w*	.*$")"

		# cache results for repeat invocations
		echo "$matches" > "${backup}-cached" &
		echo "$1" > "${backup}-query" &
		md5sum < "$PWD/tags" > "${backup}-hash" &
	fi
	[ ! -z "$matches" ] || quit "No matches found for $1"

	# multiple line match disambiguation
	num="$(echo "$matches" | wc -l)"
	if [ "$num" -gt 1 ]; then
		unset arg_ok
		if [ ! -z "$2" ]; then
			# special case 'all' opens all matching files
			case "$2" in
				all) arg_ok=1;;
			esac
			# if numeric argument is valid integer that's in range,
			# then cherry-pick desired line
			[ "$2" -eq "$2" ] 2> /dev/null &&
				[ "$2" -ge 1 ] && [ "$2" -le "$num" ] && arg_ok=1 &&
				matches="$(echo "$matches" | tail -n "+$2" | head -n 1)"
		fi
		# if no argument is passed, show listing and exit
		if [ -z "$arg_ok" ]; then
			mesg "Specify a match or use 'all' to select all matches." 1>&2
			i=1; echo "$matches" | while read -r line; do
				printf ' %d\t%s\n' "$i" "$line" 1>&2
				i=$((i + 1))
			done && exit 1
		fi
	fi

	# assemble final argument list
	matches="$(echo "$matches" | ex_parser)"
	case $? in
		1) quit "Index file is malformed";;
		2) quit "Index file is outdated";;
	esac
	set --
	for f in $(seq $(echo "$matches" | wc -l)); do
		line="$(echo "$matches" | tail -n "+$f" | head -n 1)"
		file="$(echo "$line" | cut -f2)"
		pos="$(echo "$line" | cut -f3)"
		set -- "$@" "+$pos" "$file"
	done
	$EDITOR "$@"
}

## Open an xz(1) compressed and openssl(1) encrypted file for editing.
##  -f <filename>   Prompts the user for a encryption password.
##  or --encrypt    Decrypts file for editing, re-encrypts if file is modified.
##                  Creates file if it doesn't already exist.
##                  If the file exists but isn't encrypted, user will be
##                  prompted to overwrite the original file.
##                  * Scripts can provide the following environment variables
##                    to edit the decrypted file using another command.
##                    eg. $EXTERN_EDITOR "$decrypted_file" $EXTERN_ARGS
##                  ** Requires OpenSSL 1.1.1 or later.

random_bits() {
	tr -cd 'a-z0-9' < /dev/urandom | dd count=1 bs="$1" 2> /dev/null
}

get_response() {
	stty -echo
	read -r res
	stty echo
	echo "$res"
}

prompt_user() {
	while read -r res; do
		case "$(echo "$res" | tr 'A-Z' 'a-z')" in
			y | yes) return 0;;
			n | no) return 1;;
		esac
		mesg_st "Please confirm (yes/no): "
	done
}

mode_encrypt() {
	mode='encrypt'
	# global settings
	magic='Salted__'
	cipher='-aes-256-cbc -pbkdf2'
	# temp file directory
	prefix="${XDG_RUNTIME_DIR:-/tmp}"

	for f in "$@"; do
		# file permissions
		for g in "$prefix" "$(derive_parent "$f")"; do
			[ ! -w "$g" ] && quit "'$g' is unwritable"
		done

		# randomize filename
		while :; do tmp="$prefix/${f##*/}.$(random_bits 7)"
			[ -f "$tmp" ] || break
		done

		# determine file state
		[ ! -f "$f" ] && state='new file' # file doesn't exist, do nothing
		if [ -f "$f" ]; then # is this an encrypted file?
			case "$(dd bs=8 count=1 < "$f" 2> /dev/null)" in
				$magic) state='encrypted';;
			esac
		fi
		# no state - file is plaintext, ask to overwrite when finished

		mesg_st "Password for '$f'${state:+ ($state)}: "
		pass="$(get_response)" && printf '\n'
		if [ "$state" != 'encrypted' ]; then # verify password
			orig="$pass"
			mesg_st 'Verify password: '
			pass="$(get_response)" && printf '\n'
			[ "$orig" != "$pass" ] && quit 'Passwords do not match'
			unset orig
		fi

		trap '[ ! -f "$tmp" ] || shred -z -u "$tmp"' 0 1 2 3 6
		if [ "$state" = 'encrypted' ]; then # decrypt file
			openssl enc $cipher -pass "pass:$pass" -d < "$f" | xz -d > "$tmp" ||
				quit 'Invalid password'
			init="$(sha256sum < "$tmp")" # monitor changes
		fi
		[ -z "$state" ] && cp "$f" "$tmp" # copy existing file

		# open plaintext file for editing
		[ ! -z "$EXTERN_EDITOR" ] && ext='announce'
		$ext ${EXTERN_EDITOR:-$EDITOR} "$tmp" $EXTERN_ARGS

		if [ -f "$tmp" ]; then
			if [ -z "$state" ]; then # ask to overwrite original
				mesg_st "Overwrite original file '$f'? (yes/no): "
				prompt_user && state='ok'
			fi
			if [ ! -z "$state" ] && [ "$init" != "$(sha256sum < "$tmp")" ]; then
				xz -z < "$tmp" | openssl enc $cipher -pass "pass:$pass" -e > "$f"
			fi
		fi
		unset pass state
	done
}

mode='overlay'
# overlay command line options
if [ ! -z "$1" ]; then
	# steal options not supported by GNU nano
	for f in $(echo "$1" | grep '^-' | sed 's/^\-*//'); do
		case $f in
			h | help) mode_help 1>&2 && exit 1;;
			e | ctags) shift && mode_ctags "$@" && exit;;
			f | encrypt) shift && mode_encrypt "$@" && exit;;
		esac
	done
fi

# housekeeping
# incrementally purge stale entries from filepos_history
for f in "$HOME/.nano" "$XDG_DATA_HOME/nano"; do
	hist="$f/filepos_history"
	[ -f "$hist" ] || continue
	# after 5 minutes of inactivity, drop one line per minute elapsed
	delta=$(($(date '+%s') - $(stat -c '%Y' "$hist")))
	if [ $delta -gt 300 ]; then
		line=$(((delta - 300) / 60))
		{ rm "$hist"; tail -n "+$line" > "$hist"; } < "$hist"
	fi
	break
done &

# housekeeping
# append options/refuse to open certain files
for f in "$@"; do case "$f" in
	-*) ;; # don't act on flags
	*)
		# file unwritable
		[ -d "$f" ] && quit "'$f' is a directory"
		# force line numbers on large files
		[ -f "$f" ] && [ $(wc -l < "$f") -gt 500 ] && opts='-l'
		# check if file lock exists
		lock="$(derive_parent "$f")/.${f##*/}.swp"
		if [ -f "$lock" ]; then
			# remove stale lock if pid at bytes 24-27 doesn't exist
			pid=$(dd bs=3 skip=8 count=1 < "$lock" 2> /dev/null | \
				od -t d -A n | tr -d ' ')
			if [ "$pid" -eq "$pid" ] 2> /dev/null; then # valid pid
				! ps -p "$pid" > /dev/null || quit "'$f' already in use"
			fi
			rm -f "$lock"
		fi
esac; done

wait
exec $ACTUAL_EDITOR $opts "$@"
