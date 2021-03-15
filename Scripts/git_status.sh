#!/usr/bin/env sh

# ⎇ git_status.sh v0.6
# returns repo name, branch name and status in the form '±repo:branch*'
# '-s' short form status, omit implicit information
# '-e' double-escapes ANSI escape codes for use in shell prompts
# '-n' strips color output
# '-p' print current path with embedded inline status

# color constants
clean='\e[1;32m'
staged='\e[1;33m'
dirty='\e[1;31m'
alt='\e[1;36m'
dir='\e[1;34m'
reset='\e[0m'
icon='±'

# is this a git repo?
data="$(git status -b --porcelain 2> /dev/null)" || exit 1
# branch/upstream info
info="${data%%
*}"
# index/worktree state (optional), strip leading newline
state="${data#"$info"
}"
[ "$info" != "$state" ] || unset state
# strip leading hashes
info="${info#*#* }"

# find worktree and actual git dir location
# covers git submodule and detached worktree edge cases
repo="$(git rev-parse --show-toplevel --git-dir)"
git_dir="${repo##*
}"
repo="${repo%%
*}"

# interpret branch/upstream info
# format: 'branch...upstream [ahead 1 behind 1]'
case "$info" in
	HEAD*) # detached HEAD mode
		branch="$(cut -c -7 "$git_dir/HEAD")" # unnamed commit
		tag="$(fgrep -rl "$branch" "$git_dir/refs/tags")" # is this a tag?
		if [ -f "$git_dir/packed-refs" ]; then # aggressively packed
			tag="$tag$(grep "$branch.*refs/tags" "$git_dir/packed-refs")"
		fi
		[ ! -z "$tag" ] && branch="${tag##*/}";;
	'No commits'* | 'Initial commit'*) # no commits yet
		[ -z "$(ls "$git_dir/refs/heads")" ] &&
			[ ! -f "$git_dir/packed-refs" ] && branch="(init)";;
	*) # normal mode
		branch="${info%...*}" # strip upstream name
		# extract upstream tracking if it exists
		remote="${info%\[*}"
		remote="${info#"$remote"}"
		remote="${remote#[}" remote="${remote%]}"
		if [ ! -z "$remote" ]; then
			[ "$remote" != 'gone' ] || unset remote
			for g in $remote; do
				case $g in ahead) g=' +';; behind) g=' -';; esac
				upstr="$upstr$g"
			done
		fi
esac

# interpret index/worktree state
# format: 'XX file.c'
#          ^ index
#           ^ tree
IFS='
'
for f in $state; do # accumulate state flags
	f="${f%${f#??}}"
	case "$f" in
		*\!*) continue;; # ignored
		*\?*) untracked=1; continue;;
		*U*) unmerged=1; continue;;
	esac
	[ "${f%?}" = ' ' ] || index="$index${f%?}"
	[ "${f#?}" = ' ' ] || tree="$tree${f#?}"
done
unset IFS

color="$clean" # default color
[ ! -z "$index" ] && color="$staged" && bits="$bits+" # files added
[ ! -z "$tree" ] && color="$dirty" && bits="$bits*" # files modified
[ ! -z "$untracked" ] && color="$dirty" && bits="$bits%" # untracked files
[ ! -z "$unmerged" ] && branch="<!>$branch" # merge conflict
[ -f "$git_dir/refs/stash" ] && bits="^$bits" # stash exists

# parse option flags
for f in $(echo "${@#-}" | sed 's/./& /g'); do case $f in
	s) unset icon; case "$branch" in master|main) unset branch;; esac;;
	e) color="\[$color\]"; alt="\[$alt\]"; dir="\[$dir\]"; reset="\[$reset\]";;
	n) unset color alt dir reset;;
	p) dir_mode=1;;
esac; done

# final assembly
status="$color$icon${repo##*/}${branch:+:$branch}$bits$alt$upstr$reset"
if [ ! -z "$dir_mode" ]; then
	prefix="${repo%/*}/"
	# ~/ home directory shorthand
	if [ "$HOME" = "${prefix%${prefix##"$HOME"}}" ]; then
		prefix="~${prefix##"$HOME"}"
	fi
	suffix="${PWD##"$repo"}"
	# <prefix>/±repo:branch*/<suffix>
	status="$dir${prefix}$reset${status}$dir${suffix}$reset"
fi
echo "$status"
