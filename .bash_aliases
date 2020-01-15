#!/usr/bin/env bash
# ~/.bash_aliases: executed by bash(1) for non-login shells.

# set terminal prompt
PROMPT_COMMAND=set_prompt
set_prompt() {
	c='\[\e[1;34m\]' # path color
	r='\[\e[0m\]' # reset
	path="${c}\w${r}"
	# is this a git worktree?
	git_info="$(~/Scripts/git_status.sh -e)"
	if [ ! -z "$git_info" ]; then # expand path
		topdir="$(git rev-parse --show-toplevel)"
		suffix="${PWD##"$topdir"}"
		prefix="${topdir%/*}/"
		if echo "$prefix" | grep -q "^$HOME"; then
			prefix="~${prefix##"$HOME"}" # relative path ~/
		fi
		# <prefix>/±repo:branch*/<suffix>
		path="${c}${prefix}${r}${git_info}${c}${suffix}${r}"
	fi
	# override $PS1 described in .bashrc
	PS1="\[\e[1;32m\]\u@\h\[\e[0m\]:${path}\$ "
	# update titlebar
	case "$TERM" in xterm* | rxvt*) PS1="\[\e]0;\u@\h: \w\a\]$PS1"; esac
}

# ~/.local/bin
# keeps garbage out of root partition
for f in "$HOME/.local/bin"; do
	case ":$PATH:" in
		*":$f:"*) :;;
		*) export PATH="$f:$PATH";;
	esac
done

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
	if [ ! -z "$1" ]; then # apply bold decoration
		man="$(help -m "$1" | sed -E 's/[A-Z]{2,}/\\e[1m&\\e[0m/g')"
		[ ! -z "$man" ] && printf "%b\n" "$man" | less -R
	else
		echo "Which command?"
	fi
}
