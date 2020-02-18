## ~/.bashrc: executed by bash(1) for non-login shells.

## bash specific
HISTCONTROL=ignoredups

# set terminal prompt
PROMPT_COMMAND=__set_prompt
__set_prompt() {
	c='\[\e[1;34m\]' # path color
	r='\[\e[0m\]' # reset
	path="${c}\w${r}"
	# is this a git worktree?
	if git_info="$(~/Scripts/git_status.sh -e)"; then # expand path
		topdir="$(git rev-parse --show-toplevel)"
		suffix="${PWD##"$topdir"}"
		prefix="${topdir%/*}/"
		if echo "$prefix" | grep -q "^$HOME"; then
			prefix="~${prefix##"$HOME"}" # relative path ~/
		fi
		# <prefix>/±repo:branch*/<suffix>
		path="${c}${prefix}${r}${git_info}${c}${suffix}${r}"
	fi
	# set prompt and update titlebar
	PS1="\[\e[1;32m\]\u@\h\[\e[0m\]:${path}\$ "
	case "$TERM" in xterm* | rxvt*) PS1="\[\e]0;\u@\h: \w\a\]$PS1"; esac
	# affects global state, cannot subshell
	unset c r path git_info topdir suffix prefix
}

## useful aliases
alias ls='ls --color=auto'
alias make="make -j$(grep -c '^proc' /proc/cpuinfo)"

## useful functions
# GNU nano housekeeping routines
nano() (
	share='/usr/share/nano'
	rc="$HOME/.nano"
	# override syntax for specific languages
	for f in c javascript; do
		if [ "$rc/c.syntax" -nt "$rc/$f.nanorc" ]; then
			sed "/syntax/r $rc/c.syntax" "$share/$f.nanorc" > "$rc/$f.nanorc"
		fi
	done
	# purge filepos history if older than 5 minutes
	for hist in "$rc/filepos_history"; do
		[ -f "$hist" ] &&
		[ $(($(date '+%s') - $(stat -c '%Y' "$hist"))) -gt 300 ] &&
		rm "$hist"
	done
	~/Scripts/nano_overlay.sh "$@"
)

# man-like behavior for shell built-in documentation
shell() (
	if [ ! -z "$1" ]; then # apply bold decoration
		man="$(help -m "$1" | sed -E 's/[A-Z]{2,}/\\e[1m&\\e[0m/g')"
		[ ! -z "$man" ] && printf "%b\n" "$man" | less -R
	else
		echo "Which command?"
	fi
)

# spawns QR code (typically containing a URL)
qr() (
	qrencode -s 1 -o - "${@:-$(cat /dev/stdin)}" | feh - -Z --force-aliasing;
)

# check for updates
update() (
	for f in update dist-upgrade autopurge autoclean clean; do
		printf "\e[1m[$f]\e[0m\n" && sudo apt-get $f
	done
)
