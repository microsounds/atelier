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

## Xorg server / display manager

# intel graphics override
lspci | fgrep 'VGA' | fgrep -q 'Intel' && rc='intel'

# start X on login, logout after X exits
if [ "$(tty)" = '/dev/tty1' ]; then
	[ ! -z "$rc" ] && rc="-- -config $HOME/.config/xorg/$rc.conf"
	exec startx $rc > /dev/null 2>&1
fi
