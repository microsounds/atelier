#!/usr/bin/env sh

## nano_overlay.sh v1.2 — interactive external overlay for GNU nano
## (c) 2022 microsounds <https://github.com/microsounds>, GPLv3+

# constants
# keep track of recursion level
export NANO_DEPTH=$((NANO_DEPTH + 1))
# interactive features will recursively call nano_overlay
EDITOR="$0"
# call first nano found in $PATH
ACTUAL_EDITOR='nano'
TEMP_DIR="${XDG_RUNTIME_DIR:-/tmp}"

# utilities
mesg_wipe() { printf '\r' 1>&2; }
mesg_st() { printf '%s%s' "${name:+[$name] }" "$1" 1>&2; } # for prompts
mesg() { mesg_st "$1"; printf '\n' 1>&2; }
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

## Usage: nano-overlay [OVERLAY OPTS] [--] [OPTIONS] [[+LINE[,COLUMN]] FILE]...
##
##  -h, --help      Displays this message.
##  -V, --version   Displays version and author information.
##  -i, --identity  Use an OpenSSH compatible keypair to encrypt/decrypt.
##                  This may be a private key, or a public key with the private
##                  half in the same directory or available to ssh-agent(1).
##  --              Stop processing nano_overlay arguments, passes subsequent
##                  arguments to nano untouched. Subsequent uses of -- also
##                  stops processing nano arguments, all further arguments
##                  will be interpreted as literal filenames.

mode_info() {
	$ACTUAL_EDITOR "$@"
	{ dd bs=80 count=1 2> /dev/null | tr '\0' '*'; printf '\n'; } < /dev/zero

	# output inline docs or version info
	concat='tail -n +3'
	for f in "$@"; do case "$f" in
		-V|--version) concat='head -n 2';;
	esac; done
	{ grep '^##' | sed -E 's/^## ?/ /' | $concat; } < "$0"
}

## Search and jump to source code definitions provided by POSIX ctags(1).
##  -e <tag> <#>    If a ctags index file exists in the current or a parent
##  or --ctags      directory, search through it for '<tag>' and open the file
##                  containing it's definition.
##                  If multiple matches are found, specify line number <#>
##                  or 'all' to open all matches at once.

ctags_find_root() {
	# find root directory containing ctags index
	# sets $PWD to this directory if found
	while [ ! -z "$PWD" ] && [ ! -f "$PWD/tags" ]; do PWD="${PWD%/*}"; done
	[ ! -z "$PWD" ] ||
		quit 'No index found in this or any parent directories up to /'

	# validate index and get version
	ver="$(fgrep '!_TAG_FILE_FORMAT' < "$PWD/tags" | cut -f2)"
	case "$ver" in 1 | 2);; *) quit 'Index file is invalid'; esac
}

ctags_menu() {
	# spawn interactive menu if being called from a subshell
	# re-enter ctags_mode automatically
	# xargs is used to prevent nano from seeing stdin under any circumstances
	if [ $NANO_DEPTH -gt 1 ]; then
		if fzf --version > /dev/null 2>&1; then
			msg="$(mesg_st "Matches for '$1': " 2>&1)"
			sel="$(fzf --prompt="$msg" --reverse --no-clear \
				| head -n 1)" < /dev/stdin || exit 1
			sel="${sel#	*}"
			sel="${sel%%	*}"
			echo "$sel" | xargs -o $EDITOR -e "$1"
		else
			# fallback to opening all matches if fzf is not installed
			echo 'all' | xargs -o $EDITOR -e "$1"
		fi
	else
		# standard usage: print static reentrant menu to stdout
		mesg "Specify a match or use 'all' to select all matches." 2>&1
		cat /dev/stdin
	fi
}

ex_escape() {
	# preserves backslash escapes found within ctags ex editor commands every
	# time it goes through variable expansion and command capture, this avoids
	# edge cases where literal '\\r' or '\\n' are interpreted by the shell
	sed 's,\\,\\\\,g'
}

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
			# start/end delimiter can be one of '/' or '?'
			# delete text not contained within delimited zone
			# '?' performs backwards search
			order='cat'
			de="${addr%"${addr#?}"}"
			addr="${addr#*"$de"}"; addr="${addr%"$de"*}"
			case "$de" in '?') order='tac'; esac

			# strip optional regex anchors
			[ "${addr%"${addr#?}"}" = '^' ] && addr="${addr#^}"
			[ "${addr#"${addr%?}"}" = '$' ] && addr="${addr%$}"
			# strip escapes for literal use of delimiter
			addr="$(echo "$addr" | sed -e "s,\\\\$de,$de,g")"

			# return 2 if command is outdated
			addr="$(fgrep -n "$addr" < "$file")" || return 2
			addr="$(echo "$addr" | $order)";;
		esac
		echo "${addr%%[!0-9]*}"
	done < /dev/stdin
}

mode_ctags() {
	name='ctags'

	# find ctags index
	# relative filenames will be made relative to this directory
	ctags_find_root
	[ ! -z "$1" ] || quit 'No tag query given'

	# session persistence
	unset matches
	backup="$TEMP_DIR/.${0##*/}-$name"
	if [ -f "${backup}-cached" ]; then
		read -r prev_query < "${backup}-query"
		read -r prev_hash < "${backup}-hash"
		[ "$prev_query" = "$1" ] &&
		[ "$prev_hash" = "$(md5sum < "$PWD/tags")" ] &&
		matches="$(cat "${backup}-cached" | ex_escape)"
	fi

	# discarding previous session
	if [ -z "$matches" ]; then
		# cherry-pick matching lines based on first column
		# case insensitive substring search up to first literal tab
		matches="$(grep -v '^!_TAG_' < "$PWD/tags" | \
			egrep -i "^\\w*${1}\\w*	.*$" | ex_escape)"

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
			i=1; echo "$matches" | while read -r line; do
				printf ' %d\t%s\n' "$i" "$line"
				i=$((i + 1))
			done | ctags_menu "$1"
			exit
		fi
	fi

	# assemble final argument list
	matches="$(echo "$matches" | ex_escape | ex_parser)"
	case $? in
		1) quit 'Index file is malformed';;
		2) quit 'Index file is outdated';;
	esac
	set --
	for f in $(seq $(echo "$matches" | wc -l)); do
		line="$(echo "$matches" | tail -n "+$f" | head -n 1 | cut -f2-)"
		file="${line%	*}"; pos="${line#*	}"
		set -- "$@" "+$pos" "$file"
	done

	# mode_ctags may be called from within nano's execute mode (^R^X) to implement
	# ctags jump-to-definition, many terminals will not redraw the prompt correctly
	# upon exiting the top-most nano instance when mode_ctags is used this way
	# setting TERM=linux on subshelled nano instances fixes this
	[ $NANO_DEPTH -gt 1 ] && export TERM=linux

	# same file might be opened multiple times at different positions
	# open in read-only mode to avoid lockfile warnings on the same file
	# on nano 4.8 or later
	unset multi
	for f in "$@"; do
		case "$f" in +[0-9]*) continue;; esac
		multi="$multi\n$f"
	done
	multi="$(echo "$multi" | sort | uniq -d)"
	exec $EDITOR ${multi:+-v} "$@"
}

## Enable project-wide word fragment autocomplete provided by POSIX ctags(1).
##  -c <file1>...   Enables project-wide keyword autocomplete within nano.
##  or --ctags-dict If a ctags index file exists in the current or a parent
##                  directory, append it's keywords to all files opened by
##                  nano in the form of a condensed keyword dictionary at the
##                  end of the file.
##                  Condensed keyword dictionary will be removed upon exiting.

ctags_dict_append() {
	name='ctags-dict'

	# extends nano autocomplete to include all keywords in ctags index
	# by appending condensed keyword dictionary to the end of every input file
	# magic identifier appended for easy removal
	CTAGS_DICT="$(date '+%s%N' | sha256sum | tr -s ' ' '\t' | cut -f1)"
	ctags_find_root

	for f in "$@"; do
		[ ! -f "$f" ] && continue
		{	printf '%s\n%s\n' "$CTAGS_DICT" \
				"${0##*/}: ctags in-place autocomplete keyword dictionary"
			cut -f1 | grep -v '^!_TAG_' | sort | uniq | tr -s '\n' ' '
		} < "$PWD/tags" | fold -s -w 78 | sed 's/^/# &/' >> "$f"
	done
}

ctags_dict_purge() {
	# cleanly remove ctags keyword dictionary on exit
	for f in "$@"; do
		[ ! -f "$f" ] && continue
		# don't overwrite symlinks
		[ -L "$f" ] && f="$(ls -la "$f")" && f="${f#*-> }"
		# keep permission bits on overwrite
		sed -n "/$CTAGS_DICT/q;p" < "$f" > "$f.1" &&
			dd if="$f.1" of="$f" > /dev/null 2>&1 && rm -f "$f.1"
	done
}

## Notes on encryption routines
## ** External scripts can provide the following $ENVIRONMENT_VARIABLES
##    to open the decrypted file using another command that's not nano.
##    Internally, decrypted file will be passed as follows:
##    >> $EXTERN_EDITOR $decrypted_file $EXTERN_ARGS <<
## ** Requires OpenSSL 1.1.1 (2018-09-11) or later.
## ** Requires OpenSSH 8.1 (2019-10-09) or later.

## Open AES encrypted text file with a plaintext password
##  -f <filename>   Interactively prompts user for an AES decryption password.
##  or --encrypt    Decrypts file for editing, re-encrypts if file is modified.
##                  Creates file if it doesn't already exist.
##                  If the file exists but isn't encrypted, user will be
##                  prompted to overwrite the original file.

# mode_encrypt file format (＊indicates external)
# ┬ [ openssl enc'd data ]〈───[＊password ]
# │ [ xz'd data ======== ]   (decrypt)
# V [ plaintext file === ]

# compression settings
gz='gzip -1c'
xz='xz -0c -T0'

# common
aes_magic='Salted__'
aes_crypt='openssl enc -aes-256-cbc -pbkdf2'

verify_header() {
	header="$(dd bs="${#1}" count=1)" < /dev/stdin 2> /dev/null
	case "$header" in
		"$1") return 0;;
		*) return 1;;
	esac
}

random_bytes() {
	# openssl expects human-readable keyfiles
	# files CANNOT start with NULL bytes
	# data past the first newline character is ignored
	{ dd bs="$1" count=1 | tr -d '\0\n'; } < /dev/urandom 2> /dev/null
}
random_ascii() {
	{ tr -cd 'a-z0-9' | dd bs="$1" count=1; } < /dev/urandom 2> /dev/null
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
	name='encrypt'

	for f in "$@"; do
		# empty filename?
		[ ! -z "$f" ] || continue
		# file permissions
		for g in "$TEMP_DIR" "$(derive_parent "$f")"; do
			[ ! -w "$g" ] && quit "'$g' is unwritable"
		done

		# create non-colliding filename
		while :; do tmp="$TEMP_DIR/${f##*/}.$(random_ascii 7)"
			[ -f "$tmp" ] || break
		done

		# determine file state
		[ ! -f "$f" ] && state='new' # file doesn't exist yet
		if [ -f "$f" ]; then # is this an encrypted file?
			verify_header "$aes_magic" < "$f" && state='encrypted'
		fi
		# no state: file is plaintext, ask to overwrite when finished

		# obtain encryption password from user
		mesg_st "Password for '$f'${state:+ ($state)}: "
		export pass="$(get_response)" && printf '\n'
		if [ "$state" != 'encrypted' ]; then # verify password
			orig="$pass"
			mesg_st 'Verify password: '
			pass="$(get_response)" && printf '\n'
			[ "$orig" != "$pass" ] && quit 'Passwords do not match'
			unset orig
		fi

		# attempt file unpack
		trap 'rm -rf "$tmp"*' 0 1 2 3 6
		if [ "$state" = 'encrypted' ]; then
			{ $aes_crypt -pass 'env:pass' -d | $xz -d; } < "$f" > "$tmp" ||
				quit 'Invalid password'
			init="$(sha256sum < "$tmp")" # monitor changes
		fi
		[ -z "$state" ] && cat < "$f" > "$tmp" # copy existing file

		# external script control: announce what is being done
		${EXTERN_EDITOR:+ announce} \
			${EXTERN_EDITOR:-$EDITOR} "$tmp" $EXTERN_ARGS

		# conditionally repack file on file change
		if [ -f "$tmp" ]; then
			if [ -z "$state" ]; then # no state: ask to overwrite original
				mesg_st "Overwrite original file '$f'? (yes/no): "
				prompt_user && state='ok'
			fi
			if [ ! -z "$state" ] && \
				[ "$init" != "$(sha256sum < "$tmp")" ]; then
				{ $xz | $aes_crypt -pass 'env:pass' -e; } \
					< "$tmp" > "${tmp}.1" && mv "${tmp}.1" "$f"
			fi
		fi
		unset pass state
	done
}

## Open AES encrypted text file with generic RSA keypair in PEM format
##  -j <filename>   Uses a generic RSA public key to encrypt a one-time
##  or --rsa        randomized keyfile which is used for AES encryption.
##                  User will be prompted for RSA private key passphrase for
##                  decryption if needed. ssh-agent(1) is NOT supported.
##                  Default fallback key is ~/.ssh/id_rsa if '-i' is not used.
##                  Required files will be generated or converted on first use.
##                  ** RSA private key must be in legacy PEM format.
##                     Use 'ssh-keygen -p -m pem' to convert to PEM as needed.

# mode_encrypt_rsa file format (＊indicates external)
# ┬ [ xz'd data = ]
# ╎ [ tar archive ]  ┌─[ RSA encrypted keyfile ]
# ╎    │       │     │             │
# ╎ [ enc ] [ key ]  │  (decrypt)  ├──[＊private key ]
# ╎    │       └─────┘             │
# ╎ [ openssl enc'd data ]〈───[＊plain keyfile ]
# ╎ [ xz'd data ======== ]   (decrypt)
# V [ plaintext file === ]

# specific to mode_encrypt_rsa
rsa_crypt='openssl rsautl -pkcs'
rsa_verify='openssl rsa -noout -text'

mode_encrypt_rsa() {
	name='rsa'

	# identity constants
	# fallback to ~/.ssh/id_rsa
	[ ! -z "$id_key" ] || id_key="$HOME/.ssh/id_rsa"
	rsa_private="$id_key"
	rsa_public="${rsa_private}.pub.pkcs8"

	[ -f "$rsa_private" ] ||
		quit "Expected RSA private key at '$rsa_private'"

	read -r rsa_header < "$rsa_private"
	# on first run, convert existing keys to PEM format
	if [ "$rsa_header" != '-----BEGIN RSA PRIVATE KEY-----' ]; then
		mesg "Converting private key at '$rsa_private' to PEM format."
		announce ssh-keygen -f "$rsa_private" -p -m pem ||
			quit "'$rsa_private' is not a private key"
	fi
	if [ ! -f "$rsa_public" ]; then
		mesg "Creating PKCS8 public PEM key at '$rsa_public'"
		announce ssh-keygen -f "$rsa_private" -e -m pkcs8 > "$rsa_public"
	fi

	# sanity check, obtain key length
	rsa_bits="$($rsa_verify -pubin -in "$rsa_public" \
		| egrep -o '[0-9]+' | head -n 1)"
	[ $rsa_bits -ge 1024 ] && [ $rsa_bits -le 16384 ] ||
		quit "Could not obtain RSA key length for '$rsa_private'"

	for f in "$@"; do
		# empty filename?
		[ ! -z "$f" ] || continue
		# file permissions
		for g in "$TEMP_DIR" "$(derive_parent "$f")"; do
			[ ! -w "$g" ] && quit "'$g' is unwritable"
		done

		# create non-colliding directory name
		while :; do tmp="$TEMP_DIR/${f##*/}.$(random_ascii 7)"
			[ -d "$tmp" ] || break
		done

		# determine file state
		[ ! -f "$f" ] && state='new' # file doesn't exist yet
		if [ -f "$f" ]; then # is this an encrypted file?
			{ $xz -d | tar -xO enc; } < "$f" 2> /dev/null | \
				verify_header "$aes_magic" && state='encrypted'
		fi
		# no state: file is plaintext, ask to overwrite when finished

		# attempt file unpack
		trap 'rm -rf "$tmp"*' 0 1 2 3 6
		mkdir -p "$tmp"
		mkfifo -m 600 "$tmp/pipe"
		if [ "$state" = 'encrypted' ]; then
			mesg_st 'Decrypting... '

			# write decrypted keyfile to pipe
			{	$xz -d | tar -xO key | \
				$rsa_crypt -inkey "$rsa_private" -decrypt ||
					quit 'Invalid private key or key not in PEM format'
			} < "$f" > "$tmp/pipe" &
			{	$xz -d | tar -xO enc | \
				$aes_crypt -pass "file:$tmp/pipe" -d | $xz -d ||
					quit 'Invalid passfile'
			} < "$f" > "$tmp/enc"
			init="$(sha256sum < "$tmp/enc")" # monitor changes
			mesg_wipe
		fi
		[ -z "$state" ] && cat < "$f" > "$tmp/enc" # copy existing file

		# external script control: announce what is being done
		${EXTERN_EDITOR:+ announce} \
			${EXTERN_EDITOR:-$EDITOR} "$tmp/enc" $EXTERN_ARGS

		# conditionally repack file on file change
		if [ -f "$tmp/enc" ]; then
			if [ -z "$state" ]; then # no state: ask to overwrite original
				mesg_st "Overwrite original file '$f'? (yes/no): "
				prompt_user && state='ok'
			fi
			if [ ! -z "$state" ] && \
				[ "$init" != "$(sha256sum < "$tmp/enc")" ]; then
				mesg_st 'Saving to disk... '

				# create new keyfile to match key length - PKCS1 padding
				# write decrypted keyfile to pipe
				{	random_bytes "$(((rsa_bits / 8) - 11))" \
						| tee "$tmp/pipe" \
						| $rsa_crypt -pubin -inkey "$rsa_public" -encrypt ||
							quit 'Public key not in PEM format'
				} > "$tmp/key" &

				# repack file in place, abort if interrupted
				{	rm "$tmp/enc"
					$xz | $aes_crypt -pass "file:$tmp/pipe" -e > "$tmp/enc" ||
						quit 'Interrupted or write error'
				} < "$tmp/enc"
				tar -cC "$tmp" enc key \
					| $xz > "$tmp/new" && mv "$tmp/new" "$f"
				mesg_wipe
			fi
		fi
		unset state
	done
}


## Open AES encrypted text file with a nonce value signed with SSH private key
##  -s <filename>   Uses an existing SSH private key to sign a one-time nonce
##  or --ssh-sign   value to create a keyfile which is used for AES encryption.
##                  This option allows seamless integration with ssh-agent(1),
##                  which falls back to the first available key in the agent if
##                  '-i' is not used.
##                  If a passphrase-protected key passed with '-i' is not added
##                  to the agent, you will be required to input passphrase
##                  during encryption and decryption steps.

# mode_encrypt_ssh_sign file format (＊indicates external)
# ┬ [ gzip'd data ]
# ╎ [ tar archive ]  ┌─[ one-time nonce keyfile ]
# ╎    │       │     │             │
# ╎ [ enc ] [ key ]  │  (generate) ├──[＊private key ]
# ╎    │       └─────┘             │
# ╎ [ openssl enc'd data ]〈───[＊signed nonce keyfile ]
# ╎ [ gzip'd data ====== ]   (decrypt)
# V [ plaintext file === ]

# specific to mode_encrypt_ssh_sign
nonce_bytes=1024

# cryptographically sign data with SSH private key
sign_file() {
	sig="$(ssh-keygen -Y sign -n file -f "$1")" 2> /dev/null ||
		quit "Matching private key for '$1' not found"
	echo "$sig" | sed -e '/^-/d' | tr -d '\n'

}

mode_encrypt_ssh_sign() {
	name='ssh-sign'

	# identity constants
	# fallback to first key held by ssh-agent
	if [ -z "$id_key" ]; then
		id_key=$(ssh-add -l) || quit 'Add identities to ssh-agent or use -i'
		id_key="$(echo "$id_key" | head -n 1 | tr ' ' '\t' | cut -f3)"
	fi

	for f in "$@"; do
		# empty filename?
		[ ! -z "$f" ] || continue

		# file permissions
		for g in "$TEMP_DIR" "$(derive_parent "$f")"; do
			[ ! -w "$g" ] && quit "'$g' is unwritable"
		done

		# create non-colliding directory name
		while :; do tmp="$TEMP_DIR/${f##*/}.$(random_ascii 7)"
			[ -d "$tmp" ] || break
		done

		# determine file state
		[ ! -f "$f" ] && state='new' # file doesn't exist yet
		if [ -f "$f" ]; then # is this an encrypted file?
			{ $gz -d | tar -xO enc; } < "$f" 2> /dev/null | \
				verify_header "$aes_magic" && state='encrypted'
		fi
 		# no state: file is plaintext, ask to overwrite when finished

		# attempt file unpack
		trap 'rm -rf "$tmp"*' 0 1 2 3 6
		mkdir -p "$tmp"
		mkfifo -m 600 "$tmp/pipe"
		if [ "$state" = 'encrypted' ]; then
			mesg_st 'Decrypting... '

			# reconstruct passfile from one-time nonce keyfile
			# sign with private key held by ssh-agent and write to pipe
			{ $gz -d | tar -xO key | sign_file "$id_key"; } < "$f" \
				> "$tmp/pipe" &

			{	$gz -d | tar -xO enc | \
				$aes_crypt -pass "file:$tmp/pipe" -d | $gz -d ||
					quit 'Wrong key used to sign passfile'
			} < "$f" > "$tmp/enc"
			init="$(sha256sum < "$tmp/enc")" # monitor changes
			mesg_wipe
		fi
		[ -z "$state" ] && cat < "$f" > "$tmp/enc" # copy existing file

		# external script control: announce what is being done
		${EXTERN_EDITOR:+ announce} \
			${EXTERN_EDITOR:-$EDITOR} "$tmp/enc" $EXTERN_ARGS

		# conditionally repack file on file change
		if [ -f "$tmp/enc" ]; then
			if [ -z "$state" ]; then # no state: ask to overwrite original
				mesg_st "Overwrite original file '$f'? (yes/no): "
				prompt_user && state='ok'
			fi
			if [ ! -z "$state" ] && \
				[ "$init" != "$(sha256sum < "$tmp/enc")" ]; then
				mesg_st 'Saving to disk... '

				# generate one-time nonce keyfile
				# sign with private key held by ssh-agent and write to pipe
				random_bytes "$nonce_bytes" | tee "$tmp/key" \
					| sign_file "$id_key" > "$tmp/pipe" &

				# repack file in place, abort if interrupted
				{	rm "$tmp/enc"
					$gz | $aes_crypt -pass "file:$tmp/pipe" -e > "$tmp/enc" ||
						quit 'Interrupted or write error'
				} < "$tmp/enc"

				tar -cC "$tmp" enc key \
					| $gz > "$tmp/new" && mv "$tmp/new" "$f"
				mesg_wipe
			fi
		fi
		unset state
	done
}

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

# overlay command line options
name='overlay'
unset id_key opt CTAGS_DICT
for f in "$@"; do case "$f" in

	# interactive overlay options
	# steal certain switches used by GNU nano
	-[Vh]|--version|--help) mode_info "$@" && exit;;
	-e|--ctags) shift && mode_ctags "$@" && exit;;
	-c|--ctags-dict) shift && ctags_dict_append "$@" && break;;
	-f|--encrypt) shift && mode_encrypt "$@" && exit;;
	-j|--rsa) shift && mode_encrypt_rsa "$@" && exit;;
	-s|--ssh-sign) shift && mode_encrypt_ssh_sign "$@" && exit;;
	-i|--identity) id_key="${2%.pub}" && shift 2;;

	# stop processing args meant for nano_overlay
	--) shift && break;;

	# append GNU nano options/refuse to open certain files
	*)
		# opening a directory by mistake
		[ -d "$f" ] && quit "'$f' is a directory"
		# force line numbers on large files
		[ -r "$f" ] && [ $(wc -l < "$f") -gt 500 ] && opt="${opt}l"
		# refuse to open if a valid lockfile exists
		lock="$(derive_parent "$f")/.${f##*/}.swp"
		if [ -f "$lock" ]; then
			# remove stale lockfile if pid at bytes 24-27 doesn't exist
			pid=$(dd bs=3 skip=8 count=1 < "$lock" 2> /dev/null | \
				od -t d -A n | tr -d ' ')
			if [ "$pid" -eq "$pid" ] 2> /dev/null; then # valid pid
				! ps -p "$pid" > /dev/null || quit "'$f' already in use"
			fi
			rm -f "$lock"
		fi
esac; done
[ ! -z "$opt" ] && opt="-$(echo "$opt" | tr -s 'a-z')"

wait
[ ! -z "$CTAGS_DICT" ] && trap 'ctags_dict_purge "$@" &' 0 1 2 3 6
$ACTUAL_EDITOR $opt "$@"
