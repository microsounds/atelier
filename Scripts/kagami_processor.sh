#!/usr/bin/env sh

#v# kagami v0.4.1 — static microblog processor
#v# (c) 2021 microsounds <https://github.com/microsounds>, GPLv3+
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA  02110-1335, USA.

#
#
## OPTION FLAGS
#
#h# usage: kagami [options]
#h#  clean            Recursively deletes all output files that would have
#h#                   been created under normal operation.
#h#  -h, --help       Displays help message.
#h#  -v, --version    Displays version information.
unset clean
for f in "$1"; do case "$f" in
	-*[vh]*)
		sel=$(echo "$f" | tr -d '-' | cut -c 1)
		egrep "^#$sel" < "$0" | sed 's/[^ ]* //'
		exit 1;;
	clean) clean=1;;
esac; done

#
#
## ERROR CHECKING
#
mode='error'
mesg_st() { printf '%s%s' "${mode:+[$mode] }" "$@"; } # for prompts?
mesg() { mesg_st "$@"; printf '\n'; }
quit() { mesg "$@, exiting." 1>&2; exit 1; }
require() { command -v "$1" > /dev/null; }

# Markdown utility
# Prefer cmark-gfm, fallback to standard cmark if not found.
cmark='cmark-gfm'; opts='--smart'
if require "$cmark"; then
	# enable github flavored markdown extensions
	for f in --unsafe footnotes table strikethrough autolink; do
		case $f in
			-*) opts="$opts $f";;
			*) opts="$opts -e $f"
		esac
	done
else
	cmark="${cmark%-*}"
	require "$cmark" || quit "$cmark not installed"
fi
markdown="$cmark $opts"

# Any dir or parent thereof that contains the following dirs will
# be considered the working directory.
# All operations are relative to this dir.
config='.kagami' # configuration directory
source='src'     # source markdown documents

# Kagami will run only if the 2 dirs described above actually exist,
# even if they're empty. Kagami tries to be fault-tolerant when convenient.
# Missing files aren't an issue, Kagami will only complain about it.
working_dir="$PWD"
while [ ! -z "$working_dir" ] && [ ! -d "$working_dir/$config" ]; do
	working_dir="${working_dir%/*}"
done
[ ! -z "$working_dir" ] ||
	quit "Directory '$config' not found in this or any parent dir up to /"

source_dir="$working_dir/$source"
[ -d "$source_dir" ] ||
	quit "Markdown documents expected in '$source_dir'"

config_dir="$working_dir/$config"
for f in head.htm tail.htm macros; do
	[ -f "$config_dir/$f" ] || ( mode='!'; mesg "Expected '$config_dir/$f'"; )
done

unset mode

#
#
## FILE OPERATIONS
#
# compare file mtime in a peculiar way
# if either file doesn't exist, assume first file is always newer
is_newer() (
	res="$(find "$1" -newer "$2" 2> /dev/null)" || return 0
	[ ! -z "$res" ]
)

# returns relative filename of newest file in a directory
# if dir is empty, or doesn't exist, or is actually a file, return nothing
newest_file() (
	file="$(ls -1t "$1" | head -n 1)"
	# ls echos your filename if it's a file
	[ "$1" = "$file" ] && unset file
	echo "$file"
)

#
#
## METADATA ROUTINES
#
# derive date from a timestamp
simple_date() (
	[ ! -z "$1" ] || [ "$1" -eq "$1" ] 2> /dev/null || return 1
	date -d "1970-01-01 UTC $1 seconds" '+%B %Y'
)

full_date() (
	[ ! -z "$1" ] || [ "$1" -eq "$1" ] 2> /dev/null || return 1
	date -d "1970-01-01 UTC $1 seconds" '+%d %b %Y'
)

# get page title from first '<h1>' heading in markdown file
md_title() (
	title="$(grep '^# ' < "$1" | sed 's/^# //' | head -n 1)"
	echo "${title:-${1##*/}}" # filename as fallback
)

# get created/updated timestamps from first 2 inline comments in
# file that take the form '<!--word xxxx/xx/xx-->'
md_timestamp() (
	st='^<!--'; ed='-->$'
	egrep "$st" < "$1" | sed -e "s/$st//" -e "s/$ed//" | head -n 2 |
		while read -r date; do
		# return valid dates only
		date -d "${date#* }" '+%s' 2> /dev/null
	done
)

# generate a markdown index of files in the same directory sorted by
# descending creation date, files without timestamps will not show up
# on this list
# file URLs are relative to index.md for now
md_index() (
	cd "$1" || return
	for f in *.md; do
		secs="$(md_timestamp "$f" | head -n 1)"
		if [ ! -z "$secs" ] && date="$(simple_date "$secs")"; then
			list="$list\n$secs\t* [$(md_title "$f")]($f) --- _${date}_"
		fi
	done
	# remove trailing newline and sort by date
	echo "$list" | grep . | sort -nr | cut -f2
)

#
#
## MACROS
#
# valid macro identifiers
mformat='[A-Za-z0-9_]+'

# global environment macros
VERSION="$("$0" --version | grep '^kagami')"
DOC_ROOT="$working_dir"
DATE_FUNCTION='full_date' # fallback date function

# import user-provided macros
[ -f "$config_dir/macros" ] && . "$config_dir/macros"

#
#
## MAIN ROUTINES
#
# get the filename of the newest file in the config directory
config_newest="$config_dir/$(newest_file "$config_dir")"

# go through directory recursively, all paths must be absolute
process_dir() (
	mode='error' # sanity check
	case "$1" in [!/]*) quit "'$1' not an absolute path";; esac
	! cd "$1" 2> /dev/null && quit "Could not enter '$1'" ||
	for file in *; do
		# recurse subdirectory
		[ -d "$1/$file" ] && process_dir "$1/$file"

		# generate matching output file for every markdown file found
		# file path rewritten to land outside of source dir
		case "$file" in *.md);; *) continue; esac
		orig="$1/$file"
		new="${orig%.*}.htm"
		new="$working_dir${new#$source_dir}"

		# clean mode
		# delete output files that would have been generated under
		# normal operation if they exist
		if [ ! -z "$clean" ]; then
			[ -f "$new" ] && ( mode='-'; mesg "$new"; )
			rm -rf "$new"
			continue
		fi

		# subdirs are created if they don't exist
		new_dir="${new%/*}"
		[ -d "$new_dir" ] ||
			( mode='/'; mesg "created $new_dir"; mkdir -p "$new_dir"; )


		# index files have a dynamic index and are always refreshed
		unset index
		case "$orig" in *index.md) touch "$orig"; index=1;; esac

		# generate an output file if stale or non-existent
		# non-existent files are implicitly older and will be created
		# if config dir has been modified, all files are considered stale
		if is_newer "$orig" "$new" || is_newer "$config_newest" "$new"; then
			# local environment macros
			timest="$(md_timestamp "$orig")"
			TITLE="$(md_title "$orig")"
			CREATED="$($DATE_FUNCTION $(echo "$timest" | tail -n +1 | head -n 1))"
			UPDATED="$($DATE_FUNCTION $(echo "$timest" | tail -n +2 | head -n 1))"

			# { concat; } | { macro; } > output
			# process entire output file in memory to reduce disk write latency
			{
				# concatenate page content
				cat "$config_dir/head.htm"
				echo '<!--{VERSION}-->'
				# cmark escapes macro identifiers in inline links
				$markdown < "$orig" | sed -e 's/%7B/{/g' -e 's/%7D/}/g'
				# regenerate index for this directory
				if [ ! -z "$index" ]; then
					echo '<div class="index">'
					md_index "${orig%/*}" | $markdown
					echo '</div>'
				fi
				cat "$config_dir/tail.htm"
			} | {
				# macro processing
				# convert inline links to other markdown files
				script='s,\.md,\.htm,g;'

				# queue macro substitutions into a single sed invocation
				tmp="$(cat /dev/stdin)"
				for ext in \
					$(echo "$tmp" | egrep -o "\{$mformat\}" | sort | uniq); do
					# strip braces
					int="${ext#?}"; int="${int%?}"
					# interpret inline macros as shell variables
					eval "int=\${$int}"
					# replace macro with contents of shell variable if set
					script="${script}s\`$ext\`$int\`g;"
				done
				echo "$tmp" | sed -e "$script"
			} > "$new" && ( mode='+'; mesg "$new"; )
		fi
	done
)

process_dir "$source_dir"
