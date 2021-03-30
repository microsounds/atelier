#!/usr/bin/env sh

# sideload utilities described in ~/.comforts-git
# listed git repos must have a makefile and an install recipe

finish() {
	rm -rf "$TMP"
	echo 'Done.'
	exit
}

IFS='
'
unset pkgs
for f in $(cat ~/.comforts-git); do
	case "${f%${f#?}}" in \#) continue;; esac # comments

	echo "Installing from '$f'"
	TMP="/tmp/$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=7 count=1 2> /dev/null)"
	trap 'finish' 0 1 2 3 6

	git clone "$f" "$TMP" || exit 1
	make -C "$TMP" install PREFIX="$HOME/.local" || exit 1
	rm -rf "$TMP"
done
