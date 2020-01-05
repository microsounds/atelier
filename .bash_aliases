#!/usr/bin/env bash
# ~/.bash_aliases: executed by bash(1) for non-login shells.

# terminal prompt
PROMPT_COMMAND=set_prompt
set_prompt() {
	c='\[\e[1;34m\]' # path color
	r='\[\e[0m\]' # reset
	path="${c}\w${r}"
	# is this a git worktree?
	git_info="$(~/Scripts/git_status.sh -e)"
	if [ ! -z "$git_info" ]; then # rewrite path string
		topdir_abs="$(git rev-parse --show-toplevel)"
		topdir="$topdir_abs" # create relative path
		if [ ! -z "$(echo "$topdir" | grep "^$HOME")" ]; then
			topdir="~${topdir#~}" # replace $HOME with ~
		fi
		prefix="${topdir%/*}/" # expand path into 3 parts
		suffix="$(echo "$PWD" | cut -c $((${#topdir_abs} + 2))-)"
		if [ ! -z "$suffix" ]; then suffix="/$suffix"; fi
		path="${c}${prefix}${r}${git_info}${c}${suffix}${r}" # final path
	fi
	# override $PS1 described in .bashrc
	PS1="\[\e[1;32m\]\u@\h\[\e[0m\]:${path}\$ "
	# update titlebar
	case "$TERM" in xterm* | rxvt*) PS1="\[\e]0;\u@\h: \w\a\]$PS1"; esac
}

# ~/.local/bin
# keeps garbage out of root partition
if [ -d "$HOME/.local/bin" ]; then
	export PATH="$HOME/.local/bin:$PATH"
fi

# display manager functionality
# start X on login, logout after X exits
if [ "$(tty)" = '/dev/tty1' ]; then
	exec startx > /dev/null 2>&1
fi

# useful functions
# spawns QR code (typically containing a URL)
qr() { qrencode -s 1 -o - "${@:-$(cat /dev/stdin)}" | feh - -Z --force-aliasing; }

# man-like behavior for shell built-in documentation
shell() {
	if [ ! -z "$1" ]; then
		man="$(help -m "$1" | sed -E 's/[A-Z]{2,}/\\e[1m&\\e[0m/g')"
		if [ ! -z "$man" ]; then
			printf "%b\n" "$man" | less -R
		fi
	else
		echo "Which command?"
	fi
}
