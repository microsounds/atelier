## ~/.profile: executed by the command interpreter for login shells.

# sources ~/.bashrc and ~/.bash_aliases
if [ ! -z "$BASH_VERSION" ]; then
	for rc in "$HOME/.bashrc"; do
		[ -f "$rc" ] && source "$rc"
	done
fi

# ~/.local/bin
# keeps garbage out of root partition
for lc in "$HOME/.local/bin"; do
	[ -d "$lc" ] && PATH="$lc:$PATH";
done

# display manager
# start X on login, logout after X exits
if [ "$(tty)" = '/dev/tty1' ]; then
	exec startx > /dev/null 2>&1
fi
