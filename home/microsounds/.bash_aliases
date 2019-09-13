#!/usr/bin/env bash
# ~/.bash_aliases: executed by bash(1) for non-login shells.

# ± git terminal prompt
# rewrites directory prompt with git information

source ~/Scripts/git_status.sh
PROMPT_COMMAND=set_prompt
set_prompt() {
	c='\[\e[1;34m\]' # color
	r='\[\e[0m\]' # reset
	path="${c}\w${r}"
	git_info="$(git_status -e)"
	if [ ! -z "$git_info" ]; then # rewrite path string
		topdir_abs="$(git_topdir)"
		topdir="$topdir_abs" # relative path
		if [ ! -z "$(echo "$topdir" | grep "^$HOME")" ]; then
			topdir="~${topdir#~}" # remove $HOME from path
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

# display manager functionality
# logs out after quitting X
if [ "$(tty)" = "/dev/tty1" ]; then
	exec startx
fi

# useful functions

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
qr() { fn="qr-$(date +%s).png"; qrencode -s 10 -o "$fn" "$@"; feh "$fn"; rm -v "$fn"; }
tmp() { cd "$(mktemp -d -p "$(pwd)")"; }
glcheck() { glewinfo | sort | grep -vi "gl[x_]" | sed 's/^ *//g' | grep -i "$1"; }
youtube-lq() { youtube-dl -o - -f 17 $1 | mpv - --force-seekable=yes; }
weather() { (head -7 | sed -n '1,2!p'; grep "^Location" -) <<< $(curl -s "http://wttr.in/$1"); }
moon() { curl -s "http://wttr.in/moon" | head -23; }
