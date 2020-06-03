#!/usr/bin/env sh

## nano_overlay.sh v0.4
## Overlay script that provides interactive functionality for GNU nano.
##  -h              Displays this message.

mesg_st() { printf '%s%s' "${mode:+[$mode] }" "$@"; } # for prompts
mesg() { mesg_st "$@"; printf '\n'; }
quit() { mesg "$@, exiting."; exit 1; }

derive_parent() (
	# return parent dir if path has
	# ../relative/sub/dirs or is absolute path
	# return '.' if path is in the current dir
	if echo "$@" | fgrep -q '/'; then
		path="${@%/*}"
		path="${path:-/}" # nothing left, assume '/'
	fi
	echo "${path:-.}"
)

mode_help() {
	nano "$@"
	grep '^##' "$0" | sed 's/^## //' 1>&2
	exit
}

## Search and jump to source code definitions using ctags(1).
##  -e <tag> <#>    If a ctags index file exists in the current or a parent
##                  directory, search through it for '<tag>' and open the file
##                  containing it's definition.
##                  If multiple matches are found, specify line number <#>.
##                  ** Requires ctags '-n' flag for numeric line numbers.

jump_to() {
	if [ "$(echo "$1" | cut -f3 | cut -c 1-2)" = '/^' ]; then
		quit 'ctags must be run in '-n' mode for numeric line numbers'
	fi
	file="$(echo "$1" | cut -f2)"
	line="$(echo "$1" | cut -f3 | egrep -o '[0-9]+')"
	exec nano "+$line" "$PWD/$file"
}

mode_ctags() {
	mode='ctags'
	# find root directory containing ctags index
	# all filenames are relative to this directory
	while [ ! -z "$PWD" ] && [ ! -f "$PWD/tags" ]; do PWD="${PWD%/*}"; done
	[ -z "$PWD" ] && quit 'No index found in this or any parent directories up to /'
	[ -z "$1" ] && quit 'No tag query given'

	# find matches based on first column
	for f in $(cut -f1 < "$PWD/tags" | grep -i -n "$1" | cut -d ':' -f1); do
		list="$list${f}p;"
	done
	matches="$(sed -n "$list" < "$PWD/tags")"
	[ -z "$matches" ] && quit "No matches found for $1"

	num="$(echo "$matches" | wc -l)"
	if [ "$num" -gt 1 ]; then # multiple matches
		if [ ! -z "$2" ]; then
			[ "$2" -eq "$2" ] 2> /dev/null && # validate
			[ "$2" -le "$num" ] &&
			jump_to "$(echo "$matches" | tail -n "+$2" | head -1)"
		fi
		mesg 'Select a match or be more specific.'
		echo "$matches" | nl | fold -w 80 && exit 1
	fi
	jump_to "$matches"
}

## Open an xz(1) compressed and openssl(1) encrypted file for editing.
##  -f <filename>   Prompts the user for a encryption password.
##                  Decrypts file for editing, re-encrypts if file is modified.
##                  Creates file if it doesn't already exist.
##                  If the file exists but isn't encrypted, user will be
##                  prompted to overwrite the original file.
##                  * Scripts can provide env vars $EDITOR and $EXTERN_ARGS
##                    to edit the decrypted file using a different program.
##                    eg. ${EDITOR:-nano} "$decrypted_file" $EXTERN_ARGS
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
			if ! openssl enc $cipher -pass "pass:$pass" -d < "$f" | xz -d > "$tmp"; then
				quit 'Invalid password'
			fi
			init="$(sha256sum < "$tmp")" # monitor changes
		fi
		[ -z "$state" ] && cp "$f" "$tmp" # copy existing file

		# open plaintext file for editing
		${EDITOR:-nano} "$tmp" $EXTERN_ARGS

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
if [ ! -z "$1" ]; then # steal options not supported by GNU nano
	if echo "$1" | grep -q '^-' && ! echo "$1" | grep -q '^--'; then
		for f in $(echo "$1" | sed 's/./& /g'); do
			case $f in
				h) mode_help "$@";;
				e) shift && mode_ctags "$@";;
				f) shift && mode_encrypt "$@";;
			esac
		done
	fi
	for f in "$@"; do # force quit on lockfiles and other mistakes
		if [ -f "$(derive_parent "$f")/.${f##*/}.swp" ]; then
			quit "'$f' already in use"
		elif [ -d "$f" ]; then
			quit "'$f' is a directory"
		fi
	done
fi

exec nano "$@"
