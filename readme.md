# _dotfiles—atelier_![miku]
_Dotfiles, shell scripts, and desktop rice. Home directory backup._
![scrot]
> _Pictured: Debian stable, vanilla Xorg, akari, dwm + dmenu + sxhkd, urxvt + POSIX shell scripts._

# Quick start
1. Perform a base install of Debian stable, don't select a desktop environment.
	* _Do not login to [`tty1`](.profile), you will be kicked during bootstrap._
2. Install `sudo`, add yourself to the `sudo` group and install `git`.
3. _**Apply changes to group membership by invoking the login shell.**_
	* _`exec $SHELL -l` is the easiest way to do this, or log back in manually._
4. Bootstrap the system automatically with git. This is done only once.
	```shell
	git clone --bare [remote] ~/.config/meta
	git --git-dir=$HOME/.config/meta --work-tree=$HOME reset --hard
	# set to ignore state of untracked files in $HOME
	git meta config status.showUntrackedFiles no
	```
5. _**Invoke the login shell again to reload changes to the environment.**_
6. `for f in ~/.once.d/*; do $f; done` to run post-install scripts.
	* _Sets up the package manager, installs essential packages, compiles the window manager, etc._
7. Reboot to finish.
	* _[`xinit`](.xinitrc) starts automatically upon login to [`tty1`](.profile), you will be kicked if `dwm` isn't installed._

# Usage notes
## X session startup tied to Xinit
This setup attempts to limit the use of system-wide changes to the machine.

Daemons and services required for the window manager are tied to `xinit`, avoiding the use of `systemd` unit files, cronjobs, or other stateful changes.
They are terminated when the X server exits.

## Using `git meta`
`git meta` points to a detached **bare** repo in `~/.config/meta` which manages the `$HOME` directory, allowing for in-place backup and version control of dotfiles.

This is ideal for changes within the home directory, but not for system-wide changes.

## Using `~/.once.d` post-install scripts
All system-wide changes are performed through automated scripts located in [`~/.once.d`](.once.d)

_Some scripts apply only to specific hardware, they will **NOT** touch the system even if they are run._

* System-wide changes that bypass the package manager, eg. edits to `/etc` are avoided when possible.
* Sideloaded software is installed to [`~/.local/bin`](.local/bin) instead of `/usr/local/bin`

| series | function |
| -- | -- |
| `0*` | Makes system-wide changes performed **through** the package manager, eg. installing essential packages. |
| `1*` | Makes changes to [`~/.local`](.local) file hierarchy, eg. sideloading 3rd party software. |
| `2*` | Makes system-wide changes that **bypass** the package manager, eg. changes to `/etc`. These are hacks. |

See [`~/.comforts`](.comforts) for the full list of essential packages.

# Environment notes
## Non-standard commands
Several commands have been extended into nonpure functions* with the following precedence:
1. Scripts in `~/.local/bin` that invoke the intended command with [`extern`](.local/bin/extern)
	* This is a dumb hack to emulate shell function behavior in `dmenu` and POSIX shell scripts.
2. Bash shell functions defined in [`~/.bashrc`](.bashrc)
3. Executables located in `/usr/bin`


*_Refers to any function that affects external state, such as changing `$PWD`, exporting environment variables in the current shell, purposefully mangling files, calling other utilities that affect state—basically anything that cannot be accomplished a read loop in a subshell or abusing pipes._

## `cd`
* The contents of `$OLDPWD` is preserved between sessions.
* `cd` offers the following extensions:
	| opt | function |
	| -- | -- |
	| `...` | Quickly moves out of deep nested directories containing only more directories. |
	| `-e <dirname>` | Fuzzy find and jump into a sub-directory. |


## `nano` > [`nano_overlay`](Scripts/nano_overlay.sh)
* Invoking `nano` does the following:
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
