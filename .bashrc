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

# use fallback default colors on TUI applications that
# force their own background colors
for f in nmtui; do
	eval "$f() { palette campbell; command $f \"\$@\"; palette; }"
done && unset f

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
	echo "$PWD" > "$LASTDIR"
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
		-C | init | clone | meta) ;;
		sync) # quickly sync dotfiles and ~/Git directory
				command git meta pull -v
				find ~/Git -name '*.git' -type d | while read -r f; do
					command git -C "${f%/*}" pull -v
				done && return;;
		*) command git status > /dev/null 2>&1 || alias='meta'
	esac
	command git $alias "$@"
)

# fallback to normal color scheme
# allows running macro scripts to mangle the .sc file at runtime
# remove unwanted backup files appended with .sc~
sc() (
	palette campbell
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
