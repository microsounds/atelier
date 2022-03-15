## ~/.bashrc: executed by bash(1) for non-login shells.

#
## internal use

# bash specific
HISTCONTROL=ignoredups
PROMPT_COMMAND=set_prompt

# bash-completion
. '/usr/share/bash-completion/bash_completion'

# color support
export COLOR=1; case $TERM in
	*color | linux) ;; # known color terminals
	*) [ $(tput colors) -lt 8 ] && unset COLOR
esac

# persist $OLDPWD between sessions
export LASTDIR="${XDG_RUNTIME_DIR:-/tmp}/.oldpwd"
[ -f "$LASTDIR" ] && read -r OLDPWD < "$LASTDIR"

# truncate long prompt pathnames over N characters
export PATH_WIDTH=50

# set window title and terminal prompt
# embed git status information if available
set_prompt() {
	if [ ! -z $COLOR ]; then
		u='\[\e[1;32m\]' # user/hostname color
		p='\[\e[1;34m\]' # path color
		r='\[\e[0m\]'  # reset
	fi

	# set window title with OSC '\e]0;<title>\a' and prompt
	git_path="$(path-gitstatus -pe${COLOR:-n})" \
		|| path="$(path-shorthand)" \
		|| path="('${PWD##*/}' no longer exists)" # no such file or directory
	PS1="\[\e]0;\u@\h: \w\a\]${u}\u@\h${r}:${git_path:-${p}${path}${r}}\$ "
	unset u p r path git_path

	# command history persistence across sessions
	history -a; history -c; history -r
}

# internal echo function
announce() (
	msg="$@";
	printf '\e[30;46m%s%s\e[0m\n' "$msg" \
		"$(tr '\0' ' ' < /dev/zero \
			| dd count=1 bs=$(($(tput cols) - ${#msg})) 2> /dev/null)"
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
## external use aliases/shell functions

# enable terminal swallowing for selected X applications
for f in feh mpv pcmanfm xdiskusage; do
	alias "$f"="swallow $f"
done && unset f

# ncurses high contrast fallback colors for TUI applications that make heavy
# use of background colors such as blue or red
for f in nmtui; do
	eval "$f() { palette ncurses; command $f \"\$@\"; palette; }"
done && unset f

# spawn static web server in the current directory
alias httpd='pkill busybox; busybox httpd -p 8080'

# create parent directories
alias mkdir='mkdir -p'

# prompt before overwrite
# preserve timestamps
alias cp='cp -ip'
alias mv='mv -i'

# keep ANSI colors while paging
alias less='less -R'

# use external overlay for GNU nano
alias nano='nano-overlay'

ls() (
	# files with full permissions
	export LS_COLORS='ow=107;30;01'
	# identify file types regardless of color support
	arg='--classify' # fallback
	[ ! -z $COLOR ] && arg='--color'

	command ls --literal --group-directories-first $arg "$@"
)

cd() {
	case "$1" in
		...*) # shorthand aliases for referring to parent dirs
			_a="${1#??}" && shift # convert ... into ../../ and so on
			_e='../'
			while [ ! -z "$_a" ]; do
				[ "${_a#${_a%?}}" = '.' ] && _e="$_e../"
				_a="${_a%?}"
			done
			set -- "$_e" && unset _a _e;;
		-f) # interactive fuzzy find and jump into sub-directory with fzf
			shift # usage: cd -f [optional query]
			_e="$(find . -type d | sed 's,^./,,g' | fzf ${1:+-q "$1"} \
				-1 -0 --no-multi --layout=reverse --height=90%)" \
				|| echo 'Not found.'
			set -- "$_e" && unset _e;;
	esac

	# preserve $OLDPWD between sessions
	command cd "$@"
	echo "$PWD" > "$LASTDIR"
}

# reformat bash online documentation with man pager
help() (
	[ -z "$1" ] && command help
	for f in "$@"; do # decorate bold text
		if page="$(command help -m "$f")"; then
			page="$(echo "$page" | sed -E 's/[A-Z]{2,}/\\e[1m&\\e[0m/g')"
			printf "%b" "$page" | less -R
		fi
	done
)

# search and reformat POSIX.1-2017 online documentation with man pager
posix() (
	# docs location
	docs="$HOME/.local/share/doc/susv4-2018"
	abort() {
		echo 'usage: posix [ -l ] [ section no. ] "SEARCH TERM"' 1>&2; exit 1;
	}

	[ "$1" = '-l' ] && list=1 && shift
	case "$1" in
		-l) list=1;; # list available pages
		1) docs="$docs/utilities";; # XCU - posix shell
		2) docs="$docs/functions";; # XSH - *NIX syscalls
		3) docs="$docs/basedefs";;  # XBD - C standard library
		*) abort
	esac
	[ ! -z "$list" ] && { # list available pages in section
		echo "Available entries in section $1:"
		find "$docs" -type f | while read -r str; do
			str="${str##*/}"; echo "${str%.*}"
		done | sort | paste -s | fold -s
		exit
	}

	[ "$#" -eq 2 ] || abort
	match="$(find "$docs/$2.html" -type f 2> /dev/null)" || {
		echo "'$2' not found in section $1, exiting."
		exit 1
	}
	{ pandoc -s -f html -t man | man -l -; } < "$match"
)

# implicitly set git dir to ~/.config/meta if outside a git dir
git() (
	iteratively_run() {
		command git meta "$@" &
		find ~/Git -name '*.git' -type d | sed 's,/.git$,,' \
			| xargs -I '{}' -P0 git -C '{}' "$@"
		wait
	}
	case "$1" in
		-C | init | clone | meta) ;;
		sync) # sync dotfiles and ~/Git directory in parallel
			iteratively_run pull -v && return;;
		vacuum) # run gc on dotfiles and ~/Git directory in parallel
			iteratively_run gc --aggressive --prune=now && return;;
		*) command git status > /dev/null 2>&1 || set -- meta "$@"
	esac
	command git "$@"
)

# fallback to normal color scheme
# allows running macro scripts to mangle the .sc file at runtime
# remove unwanted backup files appended with .sc~
sc() (
	palette ncurses
	# run executable sc macro scripts in the same dir if they exist
	# macro scripts must share the same initial name as .sc file
	# eg. sheet1.sc -> ./sheet1.sc*
	for f in "$@"; do
		for g in "$f"*; do
			[ -x "$g" ] && ./"$g"
		done
	done
	command sc "$@"
	for f in "$@"; do rm -rf "${f}~"; done
	palette
)

#
## accounting/timekeeping routines based around nano-overlay

# sorts a list of upcoming dates
upcoming() (
	quit() { echo "$@"; exit; }
	[ ! -z "$1" ] || quit 'usage: upcoming [file]'
	[ -f "$1" ] || quit 'File not found.'
	export EXTERN_EDITOR='cat'

	today="$(date '+%Y/%m/%d')"
	now=$(date -d "$today" '+%s')
	# expected format: one or more of 'YYYY/MM/DD\tMSG\n'
	nano-overlay -s "$1" | sed 's/#.*$//g' | sort | grep . \
		| while read -r date msg; do
		epoch=$(date -d "$date" '+%s') || exit 1
		days=$(((epoch - now) / 86400))
		case $days in # countdown
			0) away='today';;
			1) away='1 day';;
			*) away="$days days"
		esac
		printf '%s %s %s\n' "* $date" "($away)" "${msg:-(none)}"
		[ $days -lt 90 ] && ncal -b -d "$date" -H "$date"
	done || exit 1
)


# similar to gzcat for nano-overlay | ledger -f -
ledger-enc() (
	quit() { echo "$@"; exit; }
	[ ! -z "$1" ] || quit 'usage: ledger-enc [file]'
	[ -f "$1" ] || quit 'File not found.'
	file="$1" && shift
	export EXTERN_EDITOR='ledger -f'
	export EXTERN_ARGS="$@"
	nano-overlay -s "$file"
)

# rename files to a generic filename
mv-generic() (
	for f in "$1"; do
		[ -f "$1" ] || exit 1
		new="$(sha1sum < "$1" | tr ' ' '\t' | cut -f1)"
		mv -iv "$f" "$new.${f#*.}"
	done
)

#
## atelier dotfile mangling and rice routines

# automatically run ~/.once.d post-install scripts
post-install() (
	retries=10
	! is-container && [ $(id -u) -eq 0 ] && \
		{ echo 'You must not be root.'; exit 1; }
	for f in ~/.once.d/*; do
		unset iters
		while announce ">>> Running '${f##*/}'" && ! $f; do
			iters=$((iters + 1))
			announce "Retrying... (attempt $iters/$retries)"
			[ $iters -lt $retries ] && sleep 1 || exit 1
		done
	done
)

# check for updates, purge old kernel versions
# if called from a script, run in unattended mode
update() (
	env='DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a'
	case "$-" in *i*) unset env;; esac

	for f in update dist-upgrade autopurge clean; do
		announce ">>> $f"
		sudo $env apt-get "$f" || exit
	done
	# semantic versioning sort, zero-pad numbers to 3 digits
	pad="$(tr '\0' '0' < /dev/zero | dd bs=3 count=1 2> /dev/null)"
	for f in $(dpkg --get-selections | egrep '^linux-image-[0-9]+' | cut -f1 \
		| sed -E -e "s/([0-9]+)/${pad}\1/g" -e "s/0*([0-9]{${#pad}})/\1/g" \
		| sort -r | sed -E -e "s/0*([0-9]+)/\1/g" -e 's/image/\*/' \
		| tail -n +2); do
		announce "removing $f..."
		sudo $env apt-get autopurge "$f" || exit
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

# reload terminal configuration through xrdb
# accepts optional colorscheme name
reload() {
	find ~/.local/include/colors -type f | while read -r f; do
		if echo "${f##*/}" | fgrep -q "${@:-nightdrive}"; then
			sed "/#include <colors/c #include \"$f\"" ~/.xresources | xrdb -
		fi
	done
	exec urxvtc
}
