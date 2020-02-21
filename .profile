## ~/.profile: executed by the command interpreter for login shells.

# ~/.local/bin
for f in "$HOME/.local/bin"; do
	[ -d "$f" ] && PATH="$f:$PATH"
done

# is this a bash session?
if [ ! -z "$BASH_VERSION" ]; then
	for f in "$HOME/.bashrc"; do
		[ -f "$f" ] && source "$f"
	done
fi

## display manager
# provide user-specific X configuration
# start X on login, logout after X exits
if [ "$(tty)" = '/dev/tty1' ]; then
	exec startx -- -config "$HOME/.config/xorg/xorg.conf" > /dev/null 2>&1
fi
