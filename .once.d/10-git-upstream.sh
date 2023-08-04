#!/usr/bin/env sh

# install utilities from git upstream sources described in ~/.comforts-git
# note: git repos must have a makefile, ./configure script (optional) and
#       the typical 'make install PREFIX=...' metaphor to build correctly

# persistent install mode
# git sources prepended with *asterisk will be mirrored to ~/.config/${URL##*/}

# user-provided installation scripts
# installation can be customized before or after the build process with
# existing executable scripts named {pre,post}-run in
# ~/.config/upstream/${prog} or at the root of a persistently installed
# program's install directory.
# eg. you want to apply patches, mangle the install after installation, etc.

INSTALL="$HOME/.local"
PERSIST="$HOME/.config"
SCRIPTS="$HOME/.config/upstream"

finish() {
	rm -rf "$TMP"
	echo 'Done.'
	exit
}

IFS='
'
for f in $(cat ~/.comforts-git); do
	unset persist
	case "${f%${f#?}}" in
		\#*) continue;; # comments
		\*) f="${f#?}"; persist=1;; # persistent install
	esac

	# user provided clone urls are meant for git clone and can have intended
	# dir names trailing after the url
	prog="${f##*[/ ]}"; prog="${prog%.*}" # derive prog name from clone url
	f="${f%% *}"; # strip prog name from clone url
	printf '\e[1m%s\e[0m\n' "[upstream] Installing '$prog' from '$f'"

	# git clone and cd
	# persistently installed utils can have pre-existing files
	# perform git clone manually
	case $persist in
		1) # rebuild git dir in place and/or pull
			trap - 0 1 2 3 6 15
			TMP="$PERSIST/$prog"
			mkdir -p "$TMP" && cd "$TMP"
			if ! git status > /dev/null 2>&1; then
				git init
				git remote add origin "$f"
			fi
			git reset --hard
			git fetch --tags origin master || exit 1
			git merge FETCH_HEAD || exit 1;;
		*) # git clone and discard afterward
			trap finish 0 1 2 3 6 15
			TMP="$(mk-tempdir)"
			git clone --tags "$f" "$TMP" || exit 1
			cd "$TMP"
	esac

	# checkout latest and install
	git reset --hard && git checkout HEAD || exit 1

	# copy existing installation scripts if available
	[ -d "$SCRIPTS/$prog" ] && cp -v "$SCRIPTS/$prog/"* "$TMP"

	[ -x "$TMP/pre-run" ] && ./pre-run # pre-run hacks
	if [ -x "$TMP/configure" ]; then # autoconf configure
		./configure --prefix="$INSTALL" --sysconfdir='/dev/null'
	fi
	# some older programs choke if not allowed access to /etc
	make install PREFIX="$INSTALL" ||
		sudo make install PREFIX="$INSTALL" || exit 1
	[ -x "$TMP/post-run" ] && ./post-run # post-run hacks
	[ ! -z "$persist" ] || { cd .. && rm -rf "$TMP"; }
done
