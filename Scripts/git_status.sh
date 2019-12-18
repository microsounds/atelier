#!/usr/bin/env sh

# ± git status information
# if current directory is a valid git repository
# return ⎇ branch name and status indicators in the form '±repo:branch*'

# colors
CLEAN='\e[1;32m'
STAGED='\e[1;33m'
DIRTY='\e[1;31m'
alt='\e[2m'
rst='\e[0m'

strstr() { echo "$1" | grep -F "$2"; }
extract() { echo "$1" | sed -En "s/$2/\1/p"; }
git_topdir() {
	path="$(pwd)" # returns top-most level of repo
	while [ ! -d "$path/.git" ] && [ ! -z "$path" ]; do path="${path%/*}"; done
	if [ ! -z "$path" ]; then echo "$path"; fi
}
git_status() {
	if [ -x /usr/bin/git ]; then
		status="$(git status 2>&1)"
		if [ -z "$(strstr "$status" 'fatal')" ]; then
			branch="$(extract "$status" 'On branch (\w+)')" # normal branch
			path="$(git_topdir)"
			if [ -z "$branch" ]; then # detached HEAD mode
				branch="$(extract "$status" 'HEAD detached at ([a-f0-9]+)')"
			fi
			ico= ; ups= ; col="$CLEAN"; # worktree, upstream and color status indicators
			if [ ! -z "$(strstr "$status" 'to be committed')" ]; then ico="${ico}+"; col="$STAGED"; fi
			if [ ! -z "$(strstr "$status" 'not staged')" ];      then ico="${ico}*"; col="$STAGED"; fi
			if [ ! -z "$(strstr "$status" 'Untracked files')" ]; then ico="${ico}%"; col="$DIRTY"; fi
			if [ -f "$path/.git/refs/stash" ]; then ico="^${ico}"; fi # look for stash

			if [ -z "$(strstr "$status" 'diverged')" ]; then # upstream status
				upstream="$(extract "$status" '.*Your branch is (\w+).*')"
				num="$(extract "$status" '.*by ([0-9]+) commit.*')"
				if [ "$upstream" = 'ahead' ];  then ups=" ${num}^"; fi
				if [ "$upstream" = 'behind' ]; then ups=" v${num}"; fi
			else
				ups=' v!^'
			fi
			# if '-e' is passed, enclose non-printables in \[ \]
			if [ "$1" = '-e' ]; then
				col="\[${col}\]"; alt="\[${alt}\]"; rst="\[${rst}\]";
			fi
			printf '%b\n' "${col}±${path##*/}:${branch}${ico}${alt}${ups}${rst}"
		fi
	fi
}
