## ~/.bashrc: executed by bash(1) for non-login shells.

#
## internal use

# bash specific
HISTCONTROL=ignoredups

# bash-completion
. '/usr/share/bash-completion/bash_completion'

# color support
export _COLOR=1; case $TERM in
	*color | linux) ;; # known color terminals
	*) [ $(tput colors) -lt 8 ] && unset _COLOR
esac

# $OLDPWD persistence between sessions
export _LASTDIR="${XDG_RUNTIME_DIR:-/tmp}/.oldpwd"
[ -f "$_LASTDIR" ] && read -r OLDPWD < "$_LASTDIR"

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
		topdir="$(command git rev-parse --show-toplevel)"
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

# compare file mtimes
# files being compared might not exist yet, assume 1st file is always newer
is_newer() (
	res="$(find "$1" -newer "$2" 2> /dev/null)" || return 0
	[ ! -z "$res" ]
)

# internal echo function
announce() (
	printf '\e[1m%s\e[0m\n' "$@";
)

# unmap current X window and restore it after background process returns
swallow() (
	[ ! -z "$1" ] || exit 1
	WINID="$(xdotool getactivewindow)" || exit 1

	"$@" 2> /dev/null &
	xdotool windowunmap "$WINID" && wait
	xdotool windowmap "$WINID"
)

#
## external use

# create parent directories
alias mkdir='mkdir -p'

# prompt before overwrite
alias cp='cp -i'
alias mv='mv -i'

# enable terminal swallowing for selected X applications
for f in feh mpv pcmanfm xdiskusage; do
	alias "$f"="swallow $f"
done && unset f

ls() (
	# identify file types regardless of color support
	arg='--classify' # fallback
	[ ! -z $_COLOR ] && arg='--color'
	command ls --literal --group-directories-first $arg "$@"
)

cd() {
	case "$1" in
		...*) # shorthand aliases for referencing parent dirs
			_e='../' # converts ... into ../../ and so on
			for f in $(echo "${1#??}" | sed 's/./& /g'); do
				[ "$f" = '.' ] && _e="${_e}../" || break
			done && set -- "$_e";;
		-e) # fuzzy find and jump into sub-directory
			shift
			[ -z "$1" ] && echo 'Please enter a query.' && return
			_e="$(find . -type d 2> /dev/null)"
			set -- "$(echo "$_e" | grep -i "$1" | head -n 1)"
			[ -z "$@" ] && echo 'Not found.' && return;;
	esac

	# preserve $OLDPWD between sessions
	command cd "$@"
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

# implicitly set git dir to ~/.config/meta if outside a git dir
git() (
	case "$1" in
		init | clone | meta) ;;
		*) command git status > /dev/null 2>&1 || alias='meta'
	esac
	command git $alias "$@"
)

# inject custom syntax highlighting rules for C-like languages
nano() (
	my="$XDG_DATA_HOME/nano"; def='/usr/share/nano'
	for f in c javascript; do
		if is_newer "$my/stdc.syntax" "$my/$f.nanorc"; then
			sed "/^comment/r $my/stdc.syntax" > "$my/$f.nanorc" \
				< "$def/$f.nanorc"
		fi
	done
	command nano "$@"
)

# runs ledger, decrypts ledger file for viewing
# suspend to make changes to plaintext ledger directly
# changes are saved if plaintext ledger is modified
ledger() (
	file="$HOME/.private.d/ledger.dat"
	[ ! -f "$file" ] && echo "'$file' not found." && exit
	export EXTERN_EDITOR='ledger -f'
	export EXTERN_ARGS="$@"
	~/Scripts/nano_overlay.sh -f "$file"
)

# create QR code from stdin or from a string argument
qr() (
	[ ! -f /dev/stdin ] || set -- -r /dev/stdin
	qrencode -s 1 -o - "$@" | feh - -Z --force-aliasing
)

# automatically run ~/.once.d post-install scripts
post-install() (
	for f in ~/.once.d/*; do
		while announce ">>> Running '${f##*/}'" && ! $f; do
			announce 'Retrying...'
			sleep 1
		done
	done
)

# check for updates, remove old kernels
update() (
	for f in update dist-upgrade autopurge clean; do
		announce ">>> $f"
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
