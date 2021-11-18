#!/usr/bin/env sh

# install utilities from git upstream sources described in ~/.comforts-git
# note: git repos must have a makefile, ./configure script (optional) and
#       the typical 'make install PREFIX=...' metaphor to build correctly

# persistent install mode
# git sources prepended with *asterisk will be mirrored to ~/.config/${URL##*/}
# persistent install mode also allows for configuration hacks in the form of
# pre-run and post-run scripts located in their dedicated ~/.config directory
# eg. you want to apply patches, mangle the install after installation, etc.

INSTALL="$HOME/.local"
PERSIST="$HOME/.config"

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

	prog="${f##*/}"; prog="${prog%.*}" # derive dir name
	printf '\e[1m%s\e[0m\n' "[upstream] Installing '$prog' from '$f'"

	# git clone and cd
	# persistently installed utils can have pre-existing files
	# perform git clone manually
	case $persist in
		1) # rebuild git dir in place and/or pull
			trap - 0 1 2 3 6
			TMP="$PERSIST/$prog"
			mkdir -p "$TMP" && cd "$TMP"
			if ! git status > /dev/null 2>&1; then
				git init
				git remote add origin "$f"
			fi
			git fetch --tags origin master || exit 1
			git merge FETCH_HEAD || exit 1;;
		*) # git clone and discard afterward
			trap finish 0 1 2 3 6
			TMP="$(mk-tempdir)"
			git clone --tags "$f" "$TMP" || exit 1
			cd "$TMP"
	esac

	# checkout latest and install
	git reset --hard && git checkout master || exit 1

	[ -x "$TMP/pre-run" ] && ./pre-run # pre-run hacks
	if [ -x "$TMP/configure" ]; then # autoconf configure
		./configure --prefix="$INSTALL" --sysconfdir='/dev/null'
	fi
	make install PREFIX="$INSTALL" || exit 1
	[ -x "$TMP/post-run" ] && ./post-run # post-run hacks
	[ ! -z "$persist" ] || { cd .. && rm -rf "$TMP"; }
done
