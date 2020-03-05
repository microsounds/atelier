## ~/.bashrc: executed by bash(1) for non-login shells.

## bash specific
HISTCONTROL=ignoredups

# bash-completion
for f in '/usr/share/bash-completion/bash_completion'; do
	[ ! -f "$f" ] || source "$f"
done; unset f

# set terminal prompt
PROMPT_COMMAND=__set_prompt
__set_prompt() {
	u='\[\e[1;32m\]' # user/hostname color
	p='\[\e[1;34m\]' # path color
	r='\[\e[0m\]' # reset
	# is this a git worktree?
	if git_info="$(~/Scripts/git_status.sh -e)"; then # expand path
		topdir="$(git rev-parse --show-toplevel)"
		suffix="${PWD##"$topdir"}"
		prefix="${topdir%/*}/"
		if echo "$prefix" | grep -q "^$HOME"; then
			prefix="~${prefix##"$HOME"}" # relative path ~/
		fi
		# <prefix>/±repo:branch*/<suffix>
		path="${p}${prefix}${r}${git_info}${p}${suffix}${r}"
	fi
	# set prompt and update titlebar
	PS1="${u}\u@\h${r}:${path:-${p}\w${r}}\$ "
	case "$TERM" in xterm* | rxvt*) PS1="\[\e]0;\u@\h: \w\a\]$PS1"; esac
	# affects global state, cannot subshell
	unset u p r path git_info topdir suffix prefix
}

## useful aliases
alias ls='ls --color --literal --group-directories-first'
alias make="make -j$(grep -c '^proc' /proc/cpuinfo)"
alias ctags='ctags -n -R'
alias feh='feh -.'

## useful functions
# GNU nano housekeeping routines
nano() (
	share='/usr/share/nano'
	rc="$HOME/.nano"
	# override syntax for specific languages
	for f in c javascript; do
		if [ "$rc/c.syntax" -nt "$rc/$f.nanorc" ]; then
			sed "/syntax/r $rc/c.syntax" \
			    "$share/$f.nanorc" > "$rc/$f.nanorc"
		fi
	done
	# purge filepos history if older than 5 minutes
	for hist in "$rc/filepos_history"; do
		[ -f "$hist" ] &&
		[ $(($(date '+%s') - \
		     $(stat -c '%Y' "$hist"))) -gt 300 ] &&
		rm "$hist"
	done
	~/Scripts/nano_overlay.sh "$@"
)

# move up to nearest non-empty directory
cd() {
	if [ "$1" = '...' ]; then
		while true; do
			command cd .. && echo "$PWD"
			[ "$PWD" != '/' ] &&
			[ $(ls -l | grep -v '^d' | wc -l) -lt 2 ] || break
		done; return
	fi
	command cd "$@"
}

# shell documentation man pages
help() (
	[ -z "$1" ] && command help
	for f in $@; do # decorate bold text
		if page="$(command help -m "$f")"; then
			printf "$(echo "$page" | \
			sed -E 's/[A-Z]{2,}/\\e[1m&\\e[0m/g')" | less -R
		fi
	done
)

# spawns QR code (typically containing a URL)
qr() (
	qrencode -s 1 -o - "${@:-$(cat /dev/stdin)}" | \
	feh - -Z --force-aliasing;
)

# check for updates
update() (
	for f in update dist-upgrade autopurge clean; do
		printf "\e[1m[$f]\e[0m\n" && sudo apt-get $f
	done
)
