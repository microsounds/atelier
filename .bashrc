## ~/.bashrc: executed by bash(1) for non-login shells.

## bash specific
HISTCONTROL=ignoredups

# bash-completion
. '/usr/share/bash-completion/bash_completion'

# color support
export _COLOR=1; case $TERM in
	*color | linux) ;; # known color terminals
	*) [ $(tput colors) -lt 8 ] && unset _COLOR
esac

# preserve $OLDPWD between sessions
export _LASTDIR="${XDG_RUNTIME_DIR:-/tmp}/lastdir.$UID"
[ ! -f "$_LASTDIR" ] || read -r OLDPWD < "$_LASTDIR"

## internal constructs
# set terminal prompt
# embed git status information if available
PROMPT_COMMAND=_set_prompt
_set_prompt() {
	if [ ! -z $_COLOR ]; then
		u='\[\e[1;32m\]' # user/hostname color
		p='\[\e[1;34m\]' # path color
		r='\[\e[0m\]'  # reset
	fi
	# is this a git worktree?
	if git_info="$(~/Scripts/git_status.sh -${_COLOR+e}n)"; then
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
	unset u p r path git_info topdir suffix prefix
}

# compare file mtime in a peculiar way
# if either file doesn't exist, assume first file is always newer
is_newer() (
	res="$(find "$1" -newer "$2" 2> /dev/null)" || return 0
	[ ! -z "$res" ]
)

## external constructs
# create parent directories
alias mkdir='mkdir -p'

# prompt before overwrite
alias cp='cp -i'
alias mv='mv -i'

ls() (
	# identify file types regardless of color support
	arg='--classify' # fallback
	[ ! -z $_COLOR ] && arg='--color'
	command ls --literal --group-directories-first $arg "$@"
)

cd() {
	case "$1" in
		...) # quickly move out of deep nested dirs containing only more dirs
			while :; do
				command cd .. && echo "$PWD"
				[ "$PWD" != '/' ] &&
				[ $(ls -la | grep -vc '^d') -lt 2 ] || break
			done && return;;
		-e) # fuzzy find and jump into sub-directory
			shift
			[ -z "$1" ] && echo 'Please enter a query.' && return
			set -- "$(find . -type d | grep -i "$1" | head -n 1)"
			[ -z "$@" ] && echo 'Not found.' && return;;
	esac
	command cd "$@"
	# preserve $OLDPWD between sessions
	echo "$PWD" > "$_LASTDIR"
}

# runs shell documentation through a pager
help() (
	[ -z "$1" ] && command help
	for f in $@; do # decorate bold text
		if page="$(command help -m "$f")"; then
			page="$(echo "$page" | sed -E 's/[A-Z]{2,}/\\e[1m&\\e[0m/g')"
			printf "%b" "$page" | less -R
		fi
	done
)

# nano housekeeping routines
nano() (
	my="$HOME/.local/share/nano"; def='/usr/share/nano'
	# insert custom syntax rules for C-likes if builtins are older
	for f in c javascript; do
		if is_newer "$my/stdc.syn" "$my/$f.nanorc"; then
			sed "/^comment/r $my/stdc.syn" < "$def/$f.nanorc" > "$my/$f.nanorc"
		fi
	done
	hist="$my/filepos_history"
	# incrementally drop oldest filepos lines after 5 minutes
	if [ -f "$hist" ]; then
		delta=$(($(date '+%s') - $(stat -c '%Y' "$hist")))
		if [ $delta -gt 300 ]; then
			line=$(((delta - 300) / 60)) # one per minute
			{ rm "$hist"; tail -n "+$line" > "$hist"; } < "$hist"
		fi
	fi
	~/Scripts/nano_overlay.sh "$@"
)

# runs ledger, decrypts ledger file for viewing
# suspend to make changes to plaintext ledger directly
# changes are saved if plaintext ledger is modified
ledger() (
	file="$HOME/.private.d/ledger.dat"
	[ ! -f "$file" ] && echo "'$file' not found." && exit
	export EDITOR='ledger -f'
	export EXTERN_ARGS="$@"
	~/Scripts/nano_overlay.sh -f "$file"
)

# create QR code from stdin or from a string argument
qr() (
	[ ! -f /dev/stdin ] || set -- -r /dev/stdin
	qrencode -s 1 -o - "$@" | feh - -Z --force-aliasing
)

# check for updates, remove old kernels
update() (
	announce() { printf "\e[1m%s\e[0m\n" "$@";}
	for f in update dist-upgrade autopurge clean; do
		announce "$f"
		sudo apt-get "$f" || exit
	done
	for f in $(dpkg --get-selections | egrep '^linux-image-[0-9]+' \
	         | sed 's/image/*/' | cut -f1 | sort -r | tail -n +2); do
		announce "removing $f..."
		sudo apt-get autopurge "$f" || exit
	done
)

# display ANSI terminal colors
colors() (
	for f in 40 100; do
		for g in $(seq 0 7); do
			code=$((f + g))
			unset s; # generate padding
			for h in $(seq $((8 - ${#code}))); do s="$s "; done
			printf '\e[%dm%s' "$code" "$s$code"
		done
		printf '\e[0m\n'
	done
)

# reload terminal configuration, pass optional colorscheme name
reload() {
	find ~/.local/include/colors -type f | while read -r f; do
		if echo "${f##*/}" | fgrep -q "${@:-nightdrive}"; then
			sed "/#include/a #include \"$f\"" ~/.Xresources | xrdb -
		fi
	done
	exec urxvtc
}
