## ~/.bashrc: executed by bash(1) for non-login shells.

## bash specific
HISTCONTROL=ignoredups

# bash-completion
for f in '/usr/share/bash-completion/bash_completion'; do
	[ ! -f "$f" ] || source "$f"
done; unset f

# color support
__COLOR=1; case $TERM in
	*color | linux) ;; # known color terminals
	*) [ $(tput colors) -lt 8 ] && unset __COLOR
esac

# set terminal prompt
PROMPT_COMMAND=__set_prompt
__set_prompt() {
	if [ ! -z $__COLOR ]; then
		u='\[\e[1;32m\]' # user/hostname color
		p='\[\e[1;34m\]' # path color
		r='\[\e[0m\]'  # reset
	fi
	# is this a git worktree?
	if git_info="$(~/Scripts/git_status.sh -${__COLOR+e}n)"; then
		topdir="$(git rev-parse --show-toplevel)"
		suffix="${PWD##$topdir}"
		prefix="${topdir%/*}/"
		# if $HOME is a git repo, relative path aliasing will fail
		if echo "$prefix" | grep -q "^$HOME"; then
			prefix="~${prefix##$HOME}"
		fi
		# <prefix>/±repo:branch*/<suffix>
		path="${p}${prefix}${r}${git_info}${p}${suffix}${r}"
	fi
	# set window title and prompt
	PS1="\[\e]0;\u@\h: \w\a\]${u}\u@\h${r}:${path:-${p}\w${r}}\$ "
	# affects global state, cannot subshell
	unset u p r path git_info topdir suffix prefix
}

## useful aliases
alias make="make -j$(grep -c '^proc' /proc/cpuinfo)"
alias ctags='ctags -n -R'
alias feh='feh -.'

## useful functions
# GNU nano housekeeping routines
nano() (
	share='/usr/share/nano'
	rc="$HOME/.nano"
	hist="$rc/filepos_history"
	for f in c javascript; do # prepend c syntax rules
		if [ "$rc/stdc.syntax" -nt "$rc/$f.nanorc" ]; then
			sed "/syntax/r $rc/stdc.syntax" \
			    "$share/$f.nanorc" > "$rc/$f.nanorc"
		fi
	done
	# purge filepos history if older than 5 minutes
	if [ -f "$hist" ]; then
		delta=$(($(date '+%s') - $(stat -c '%Y' "$hist")))
		[ $delta -gt 300 ] && rm "$hist"
	fi
	~/Scripts/nano_overlay.sh "$@"
)

ls() (
	arg='--classify' # color support fallback
	[ ! -z $__COLOR ] && arg='--color'
	command ls --literal --group-directories-first $arg "$@"
)

# runs ledger, decrypts ledger file for viewing
# suspend to make changes to plaintext ledger directly
ledger() (
	file="$HOME/.private.d/ledger.dat"
	[ ! -f "$file" ] && echo "'$file' not found." && exit
	export EDITOR='ledger -f'
	export EXTERN_ARGS="$@"
	~/Scripts/nano_overlay.sh -f "$file"
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
	feh - -Z --force-aliasing
)

# check for updates
update() (
	for f in update dist-upgrade autopurge clean; do
		printf "\e[1m[$f]\e[0m\n" && sudo apt-get $f || exit
	done
)

# switch terminal color palette
tcolor() {
		find ~/.local/include/colors -type f | while read plt; do
			if echo "${plt##*/}" | fgrep -q "$@"; then
				sed "/#include/a #include \"$plt\"" ~/.Xresources | xrdb -
			fi
		done
		exec urxvtc
}
