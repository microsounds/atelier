# dotfiles![miku] — _a  t  e  l  i  e  r_
_Dotfiles, shell scripts, and desktop rice. Home directory backup._
![scrot]
> _Pictured: Debian stable, vanilla Xorg, akari, dwm + dmenu + sxhkd, urxvt + POSIX shell scripts._

# Quick start
1. Perform a base installation of Debian stable.
	* _Do not login to [`tty1`](.profile), you will be kicked during bootstrap._
2. Install `sudo`, add yourself to the `sudo` group and install `git`.
	* _Group membership changes apply upon next login._
3. Bootstrap the system automatically using git. This is done only once.
	```shell
	git clone --bare [remote] ~/.config/meta
	git --git-dir=$HOME/.config/meta --work-tree=$HOME reset --hard
	# Set to ignore state of untracked files in $HOME
	git meta config status.showUntrackedFiles no
	# Re-invoke the login shell to reload the environment for the next step
	exec $SHELL -l
	```
4. `for f in ~/.once.d/*; do $f; done` to run post-install scripts.
	* _Sets up the package manager, installs essential packages, compiles the window manager, etc._ 
5. Reboot to finish.
	* _[`xinit`](.xinitrc) starts automatically upon login to [`tty1`](.profile), you will be kicked if `dwm` isn't installed._

# Usage notes
## Using `git meta`
`git meta` points to a detached **bare** repo in `~/.config/meta` which manages the `$HOME` directory, allowing for in-place backup and version control of dotfiles.

This is ideal for changes within the home directory, but not for system-wide changes.

## Using `~/.once.d` post-install scripts
All system-wide changes are performed through automated scripts located in `~/.once.d`

_Some scripts apply only to specific hardware, they will **NOT** touch the system even if they are run._

* System-wide changes that bypass the package manager, eg. edits to `/etc` are avoided when possible.
* Sideloaded software is installed to `~/.local/bin` instead of `/usr/local/bin`

| series | function |
| -- | -- |
| `0*` | Makes system-wide changes performed **through** the package manager, eg. installing essential packages. |
| `1*` | Makes changes to `~/.local` file hierarchy, eg. sideloading 3rd party software. |
| `2*` | Makes system-wide changes that **bypass** the package manager, eg. changes to `/etc`. These are hacks. |

See [`~/.comforts`](.comforts) for the full list of essential packages.

# Environment notes
## Overloaded commands
Some commands are overloaded to enable non-default behavior in several ways.
1. Shell functions defined in [`~/.bashrc`](.bashrc)
2. Executables scripts in `~/.local/bin` that invoke the intended command with [`extern`](.local/bin/extern)
	* This is a dumb hack to emulate shell function behavior in `dmenu` and POSIX shell scripts.

## `nano` > [`nano_overlay`](Scripts/nano_overlay.sh)
* Invoking `nano` calls a shell function that does the following:
	* Generates customized syntax files for C-like languages.
	* Purges old file cursor positions.
* Arguments are passed verbatim to `nano_overlay` which offers the following extensions:
	| opt | function |
	| -- | -- |
	| `-f <file>` | Opens `xz > openssl` encrypted files. |
	| `-e <tag>`  | Looks for a `ctags` index file, jumps to file containing tag definition. |

## [`git_status`](Scripts/git_status.sh) > `$PS1`
* Returns colorized short form git repo status information from `git status` porcelain version 1.
	* _Does nothing if invoked outside of a valid git repo worktree._
* Makes wild guesses about repo state via _{ab,pre}sence_ of specific files in `.git` folder.
	* _This was done deliberately to reduce latency._
* When generating `$PS1` string, output from script replaces the top-level directory of the git repo in variable `$PWD`:
	* __`~/path/to/repo/sub/dir`__
	* __`~/path/to/±repo:branch*/sub/dir`__

[scrot]: https://i.imgur.com/yaVgrN7.png
[miku]: https://i.imgur.com/fxBi6Qg.png
