#!/usr/bin/env sh

## nano_overlay.sh v0.5
## Overlay script that provides interactive functionality for GNU nano.
##  -h, --help      Displays this message.

# use nano overlay instead of standard nano for interactive features
ACTUAL_EDITOR='/usr/bin/nano'
EDITOR="$0"

mesg_st() { printf '%s%s' "${mode:+[$mode] }" "$@"; } # for prompts
mesg() { mesg_st "$@"; printf '\n'; }
quit() { mesg "$@, exiting." 1>&2; exit 1; }

derive_parent() (
	# return parent dir if path has
	# ../relative/sub/dirs or is absolute path
	# return '.' if path is in the current dir
	if echo "$@" | fgrep -q '/'; then
		path="${@%/*}"
		path="${path:-/}" # if nothing left, assume '/'
	fi
	echo "${path:-.}"
)

mode_help() {
	$ACTUAL_EDITOR -h
	grep '^##' "$0" | sed 's/^## //'
}

## Search and jump to source code definitions provided by ctags(1).
##  -e <tag> <#>    If a ctags index file exists in the current or a parent
##  or --ctags      directory, search through it for '<tag>' and open the file
##                  containing it's definition.
##                  If multiple matches are found, specify line number <#>.
##                  ** Requires ctags '-n' flag for numeric line numbers.

jump_into() (
	file="$(echo "$@" | cut -f2)"
	pos="$(echo "$@" | cut -f3 | egrep -o '[0-9]+')"
	$EDITOR "+$pos" "$PWD/$file"
)

mode_ctags() {
	mode='ctags'
	# find root directory containing ctags index
	# all filenames are relative to this directory
	while [ ! -z "$PWD" ] && [ ! -f "$PWD/tags" ]; do PWD="${PWD%/*}"; done
	[ ! -z "$PWD" ] ||
		quit 'No index found in this or any parent directories up to /'

	# validate index and get version
	ver="$(fgrep '!_TAG_FILE_FORMAT' "$PWD/tags" | cut -f2)"
	case "$ver" in 1 | 2);; *) quit 'Index file is invalid'; esac
	fgrep -q '/^' "$PWD/tags" &&
		quit 'Index file must be in numeric '-n' mode'

	# find matches based on first column
	[ ! -z "$1" ] || quit 'No tag query given'
	for f in $(cut -f1 < "$PWD/tags" | grep -i -n "$1" | cut -d ':' -f1); do
		list="$list${f}p;"
	done
	# cherry-pick matches from index file
	matches="$(sed -n "$list" < "$PWD/tags")"
	[ ! -z "$matches" ] || quit "No matches found for $1"

	num="$(echo "$matches" | wc -l)"
	if [ "$num" -gt 1 ]; then # multiple matches
		if [ ! -z "$2" ]; then
			# valid number
			[ "$2" -eq "$2" ] 2> /dev/null &&
			# that's in range
			[ "$2" -ge 1 ] && [ "$2" -le $num ] &&
			jump_into "$(echo "$matches" | tail -n +$2 | head -n 1)"
		fi
		mesg 'Select a match or be more specific.'
		i=1; echo "$matches" | while read -r line; do
			printf ' %d\t%s\n' "$i" "$line"
			i=$((i + 1))
		done && exit 1
	fi
	jump_into "$matches"
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

random_bits() { tr -cd 'a-z0-9' < /dev/urandom | head -c $1; }

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
	magic='openssl'
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

		# is this an encrypted file?
		[ ! -f "$f" ] && state='new file' # file doesn't exist, do nothing
		[ -f "$f" ] && file -b "$f" | grep -q "^$magic" && state='encrypted'
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
		${EXTERN_EDITOR:-$EDITOR} "$tmp" $EXTERN_ARGS

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
	exit
}

# overlay command line options
mode='overlay'
if [ ! -z "$1" ]; then
	# steal options not supported by GNU nano
	for f in $(echo "$1" | grep '^-' | sed 's/^\-*//'); do
		case $f in
			h | help) mode_help 1>&2 && exit 1;;
			e | ctags) shift && mode_ctags "$@" && exit;;
			f | encrypt) shift && mode_encrypt "$@" && exit;;
		esac
	done

	# normal mode
	# blindly make assumptions about arguments
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
				pid=$(od -j 24 -N 3 -t d -A n < "$lock" | tr -d ' ')
				! ps -p "$pid" > /dev/null || quit "'$f' already in use"
				rm -f "$lock"
			fi
	esac; done
fi

exec $ACTUAL_EDITOR $opts "$@"
