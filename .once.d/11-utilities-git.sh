#!/usr/bin/env sh

# install utilities described in ~/.comforts-git
# listed git repos must have a makefile and a conventional install recipe

INSTALL="$HOME/.local"

finish() {
	rm -rf "$TMP"
	echo 'Done.'
	exit
}

trap finish 0 1 2 3 6

IFS='
'
unset pkgs
for f in $(cat ~/.comforts-git); do
	case "${f%${f#?}}" in \#) continue;; esac # comments

	echo "Installing from '$f'"
	TMP="$(mk-tempdir)"
	git clone "$f" "$TMP" || exit 1
	if [ -x "$TMP/configure" ]; then # autoconf configure
		cd "$TMP" && ./configure --prefix="$INSTALL"
	fi
	make -C "$TMP" install PREFIX="$INSTALL" || exit 1
	rm -rf "$TMP"
done
