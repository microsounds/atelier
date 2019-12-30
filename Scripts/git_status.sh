#!/usr/bin/env sh

# git_status.sh v0.3
# returns repo name, ⎇ branch name, and status indicators in the form '±repo:branch*'
# pass '-e' to double-escape ANSI color codes
# bash ignores escape codes when calculating $PS1 length

# colors
clean='\e[1;32m'
staged='\e[1;33m'
dirty='\e[1;31m'
alt='\e[1;36m'
reset='\e[0m'

data="$(git status -b --porcelain=v2 2>&1)"
if [ $? -eq 0 ]; then
	# repo name
	repo="$(git rev-parse --show-toplevel)"
	# branch info
	info="$(echo "$data" | grep '^#' | cut -d ' ' -f3-)"
	for f in $(echo "$info" | sed -n 2p); do
		case $f in # use commit hash for detached head
			\(detached\)) branch="$(echo "$info" | sed -n 1p | cut -c -7)";;
			*) branch="$f";;
		esac
	done
	# upstream info
	for f in $(echo "$info" | sed -n 4p); do # filter out +0 -0
		case $f in +0);; -0);; *) ups="$ups $f";; esac
	done
	# determine state
	color="$clean" # default
	state="$(echo "$data" | grep -v '^#' | cut -d ' ' -f2)"
	[ ! -z "$(echo "$state" | cut -c 1 | tr -d '.')" ] && color="$staged" && bits="$bits+"
	[ ! -z "$(echo "$state" | cut -c 2 | tr -d '.')" ] && color="$dirty" && bits="$bits*"
	[ ! -z "$(echo "$state" | grep '^?')" ] && color="$dirty" && bits="$bits%" # untracked
	[ ! -z "$(echo "$state" | grep '^u')" ] && branch="<!>$branch" # merge conflict
	[ -f "$repo/.git/refs/stash" ] && bits="^$bits"
	if [ "$1" = '-e' ]; then color="\[$color\]"; alt="\[$alt\]"; reset="\[$reset\]"; fi
	printf '%b' "$color±${repo##*/}:$branch$bits$alt$ups$reset"
fi
