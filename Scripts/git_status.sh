#!/usr/bin/env sh

# git_status.sh v0.2
# returns repo name, ⎇ branch name, and status indicators in the form '±repo:branch*'
# if current directory is not a valid git work-tree, returns non-zero

# colors
clean='\e[1;32m'
staged='\e[1;33m'
dirty='\e[1;31m'
alt='\e[1;36m'
reset='\e[0m'

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
	return 1
else
	repo="$(git rev-parse --show-toplevel)"
	data="$(git status -b --porcelain=v2)"
	# branch info
	branch="$(echo "$data" | grep 'branch.head' | cut -d ' ' -f3)"
	if [ "$branch" = '(detached)' ]; then # use commit hash instead
		branch="$(echo "$data" | grep 'branch.oid' | cut -d ' ' -f3 | cut -c 1-7)"
	fi
	# upstream info
	ups="$(echo "$data" | grep 'branch.ab' | cut -d ' ' -f3-4)" # delete +0 -0 stats
	ups="$(echo "$ups" | sed -E -e 's/[+-0]{2}//g' -e 's/^ *//g' -e 's/ *$//g')"
	# determine state
	color="$clean" stat= # defaults
	state="$(echo "$data" | egrep -o '^[?12] [MARDRCU.]{2}?')"
	if [ ! -z "$(echo "$state" | cut -d ' ' -f2 | cut -c 1 | egrep -v '[?.]')" ]; then
		color="$staged" && stat="$stat+" # staged files exist
	fi
	if [ ! -z "$(echo "$state" | cut -d ' ' -f2 | cut -c 2 | egrep -v '[?.]')" ]; then
		color="$dirty" && stat="$stat*" # unstaged files exist
	fi
	if [ ! -z "$(echo "$state" | grep '^?')" ]; then
		color="$dirty" && stat="$stat%" # untracked files exist
	fi
	[ -f "$repo/.git/refs/stash" ] && stat="^$stat" # stash exists
	printf "%b" "$color±$(basename "$repo"):$branch$stat$alt${ups:+ $ups}$reset"
	return 0
fi
