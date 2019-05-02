#!/usr/bin/env sh

# hime v0.2 - locates and jumps into any C source code definition
# usage: hime [options] [identifier|func args|filename] [#]
# 	-t	type_name / #define MACRO
# 	-f	function_name / #define macro()
# 	-d	forward declared function_name
# 	-l	list matches only, do not jump
# 	-h	show this help message
# 	[#]	jump into result # if multiple matches are found

TYPES='^([A-Za-z0-9_#\-\*] *)+(\{.*\}?)?;?(\/\*.*)?$' # types/obj macro definitions
FUNC='^([A-Za-z0-9_#\-\*] *){3,}\(.*\)(.*\/\*.*)?$' # function/func macro definitions
FWD='s/\$/;$/g' # forward decs

help() { grep "^# " "$0" | sed -e 's/# //g' -e "s/hime/${0##*/}/g"; }
jump_into() { nano "+$1" "$2"; }
get_field() { echo "$1" | cut -d ':' -f$2; }
list_matches() {
	IFS='
	'; i=1
	echo "Matches for '$2':"
	for line in $1; do
		echo "[$i] $line"
		i=$((i + 1))
	done
}
find_matches() {
	matches="$(grep -rnIE "$1")" # find regex matches
	matches="$(echo "$matches" | grep -E "$2")" # add'l pattern
	[ -z "$matches" ] && echo "Not found." && exit 1
	num=$(echo "$matches" | wc -l)
	sel=${3:-1}
	if [ $num -gt 1 ] && [ -z "$3" ]; then
		list_matches "$matches" "$2" && exit 1
	elif [ $sel -lt 1 ] || [ $sel -gt $num ]; then
		echo "Range exceeded." && exit 1
	fi
	if [ ! -z "$nojump" ]; then # list mode
		list_matches "$matches" "$2"
	else
		matches="$(echo "$matches" | sed -n "${sel}p")" # select
		jump_into "$(get_field "$matches" 2)" "$(get_field "$matches" 1)"
	fi
}

regex= # global options
query=
idx=
nojump=
[ $# -lt 1 ] || [ $# -gt 3 ]] && help && exit 1
for arg in "$@"; do # parse arguments
	if [ $(expr index "$arg" '-') -eq 1 ]; then # split flag
		for f in $(echo "${arg#-}" | sed 's/./& /g'); do
			[ "$f" = "t" ] && regex="$TYPES"
			[ "$f" = "f" ] && regex="$FUNC"
			[ "$f" = "d" ] && regex="$(echo "$FUNC" | sed "$FWD")"
			[ "$f" = "l" ] && nojump=1
			[ "$f" = "h" ] && help && exit
		done
	elif [ "$arg" -eq "$arg" ] 2> /dev/null; then # numeric
		idx="$arg"
	else
		query="$arg"
	fi
done
[ -z "$regex" ] && echo "Select a search mode." && exit 1
[ -z "$query" ] && echo "No pattern to search." && exit 1
find_matches "$regex" "$query" "$idx"
