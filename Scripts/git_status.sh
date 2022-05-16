#!/usr/bin/env sh

# ⎇ git_status.sh v0.7
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

# get root of worktree, git dir location, and current commit short-ref
# covers edge cases incl. git submodules, detached worktrees and certain forms
# of symlink abuse
parse="$(git rev-parse \
	--show-cdup --git-dir --short HEAD)" 2> /dev/null

# is this a git repo?
# non-zero exit codes are ignored because '--short HEAD' can return an error
# under newly init'ed repos
# no captured output guarantees this isn't a git repo
case "$parse" in ?*);; *) exit 1;; esac

IFS='
'
for f in repo git_dir short_ref; do
	sel="${parse%%
*}"
	eval "$f=\"$sel\""
	parse="${parse#"$sel"
}"
done
unset IFS sel parse

# resolve relative root of worktree
# dumb hack that avoids issues with symlinks to worktrees where output of
# '--show-toplevel' doesn't match $PWD
# DO NOT navigate into symlinks to dirs nested within a worktree, a symlink
# target of 'repo/sub/sub/dir' will return ../../../ and break the script.
repo="$(cd "$repo"; echo "$PWD")"

# ignore untracked files in very large repos to improve latency
[ ${#short_ref} -gt 10 ] && speedy='--untracked-files=no'

# get branch, upstream, index, and worktree info
data="$(git status -b $speedy --porcelain)" 2> /dev/null
# branch/upstream info
info="${data%%
*}"
# index/worktree state (optional), strip leading newline
state="${data#"$info"
}"
[ "$info" != "$state" ] || unset state
# strip leading hashes
info="${info#*#* }"

# interpret branch/upstream info
# format: 'branch...upstream [ahead 1 behind 1]'
case "$info" in
	HEAD*) # detached HEAD mode
		branch="$short_ref" # unnamed commit
		tag="$tag$(fgrep -rl "$branch" "$git_dir/refs/tags")" # is this a tag?
		if [ -f "$git_dir/packed-refs" ]; then # aggressively packed
			# dig deeper for packed simple or annotated tags
			tag="$tag$(grep "$branch.*refs/tags" "$git_dir/packed-refs")" ||
			tag="$tag$(fgrep -B1 "^$branch" "$git_dir/packed-refs" | head -n 1)"
		fi
		[ ! -z "$tag" ] && branch="${tag##*/}";;
	'No commits'* | 'Initial commit'*) # no commits yet
		branch="(init)";;
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
unset untracked unmerged index tree
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
[ -f "$git_dir/refs/stash" ] || { # stash exists?
	[ -f "$git_dir/packed-refs" ] &&
		fgrep -q 'refs/stash' "$git_dir/packed-refs"
} && bits="^$bits"

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
