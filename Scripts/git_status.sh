#!/usr/bin/env sh

# git_status.sh v0.5
# returns repo name, ⎇ branch name, and status indicators in the form '±repo:branch*'
# '-e' double-escapes ANSI escape codes for use in shell prompts
# '-n' strips color output

# colors
clean='\e[1;32m'
staged='\e[1;33m'
dirty='\e[1;31m'
alt='\e[1;36m'
reset='\e[0m'

# is this a git repo?
data="$(git status -b --porcelain 2> /dev/null)" || exit

# repo location
repo="$(git rev-parse --show-toplevel)"
git_dir="$repo/.git" # is this a submodule?
[ ! -f "$git_dir" ] || read _ git_dir < "$git_dir"

# branch info
info="$(echo "$data" | head -1 | tr -s '#.,[]() ' '\n' | grep '.')"
for f in $(echo "$info" | head -1); do
	case $f in
		HEAD) # detached HEAD mode
			branch="$(cut -c -7 "$git_dir/HEAD")" # unnamed commit
			tag="$(fgrep -rl "$branch" "$git_dir/refs/tags")" # is this a tag?
			if [ -f "$git_dir/packed-refs" ]; then # aggressively packed
				tag="$tag$(grep "$branch.*refs/tags" "$git_dir/packed-refs")"
			fi
			[ ! -z "$tag" ] && branch="${tag##*/}";;
		No) # no branches exist or branch named 'No'
			[ -z "$(ls "$git_dir/refs/heads")" ] &&
			[ ! -f "$git_dir/packed-refs" ] && branch="(init)" || branch="$f";;
		*) # normal mode
			branch="$f" # obtain upstream info if available
			for g in $(echo "$info" | tail -n +3); do
				case $g in ahead) g=' +';; behind) g=' -';; esac
				ups="$ups$g"
			done
	esac
done

# index/work-tree state
color="$clean" # default
state="$(echo "$data" | tail -n +2 | cut -c -2)"
[ ! -z "$(echo "$state" | cut -c 1 | tr -d '? ')" ] && color="$staged" && bits="$bits+"
[ ! -z "$(echo "$state" | cut -c 2 | tr -d '? ')" ] && color="$dirty" && bits="$bits*"
echo "$state" | grep -q '?' && color="$dirty" && bits="$bits%" # untracked files
echo "$state" | grep -q 'U' && branch="<!>$branch" # merge conflict
[ -f "$git_dir/refs/stash" ] && bits="^$bits" # stash exists

# parse color options
if [ ! -z "$1" ]; then
	for f in $(echo "${1#-}" | sed 's/./& /g'); do
		case $f in
			e) color="\[$color\]" && alt="\[$alt\]" && reset="\[$reset\]";;
			n) unset color alt reset;;
		esac
	done
fi

echo "$color±${repo##*/}:$branch$bits$alt$ups$reset"
