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
	repo="$(git rev-parse --show-toplevel)"
	info="$(echo "$data" | grep '^#' | cut -d ' ' -f3-)"
	state="$(echo "$data" | grep -v '^[#?]' | cut -d ' ' -f2)"
	untracked="$(echo "$data" | grep '^?')"
	unmerged="$(echo "$data" | grep '^u')"

	# branch name
	branch="$(echo "$info" | sed -n 2p)"
	if [ "$branch" = '(detached)' ]; then # use commit hash instead
		branch="$(echo "$info" | sed -n 1p | cut -c -7)"
	fi
	# upstream info
	ups= upstream="$(echo "$info" | sed -n 4p)"
	for f in $upstream; do # filter out +0 -0
		case $f in +0);; -0);; *) ups="$ups $f";; esac
	done
	# determine state
	color="$clean" bits= # defaults
	[ ! -z "$(echo "$state" | cut -c 1 | grep -v '\.')" ] && color="$staged" && bits="$bits+"
	[ ! -z "$(echo "$state" | cut -c 2 | grep -v '\.')" ] && color="$dirty" && bits="$bits*"
	[ ! -z "$untracked" ] && color="$dirty" && bits="$bits%"
	[ ! -z "$unmerged" ] && branch="<!>$branch"
	[ -f "$repo/.git/refs/stash" ] && bits="^$bits"
	if [ "$1" = '-e' ]; then color="\[$color\]"; alt="\[$alt\]"; reset="\[$reset\]"; fi
	printf '%b' "$color±${repo##*/}:$branch$bits$alt$ups$reset"
fi
