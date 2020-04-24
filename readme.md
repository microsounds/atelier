# ![miku] _a  t  e  l  i  e  r_ ![miku]
Dotfiles, shell scripts, and desktop rice. Home directory backup.
![scrot]
> _Pictured: Debian stable, vanilla Xorg, miku, dwm + dmenu + sxhkd, urxvt + POSIX shell scripts._

# Quick start
1. Perform a base installation of Debian stable.
2. Install `sudo`, add yourself to the `sudo` group and install `git`.
	* _Group membership changes apply upon next login._
3. Bootstrap the system automatically using git.
	* _This is needed only once._
	```shell
	git clone --bare [remote] ~/.config/meta
	git --git-dir=$HOME/.config/meta --work-tree=$HOME reset --hard
	# Disregard worktree state of $HOME, set to ignore untracked files
	git meta config status.showUntrackedFiles no
	```
4. `cat ~/.comforts | xargs apt-get install -y` to install essential packages.
5. `for f in ~/.once.d/*; do $f; done` to run post-install scripts.
	* _These build and install the window manager, among other things._
6. Reboot to finish.
	* _[`xinit`](.xinitrc) starts automatically upon login to [`tty1`](.profile), you will be kicked if `dwm` isn't installed._

# Usage notes
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

## Using `git meta`
`git meta` points to a detached _**bare**_ repo in `~/.config/meta` which manages the `$HOME` directory, allowing for in-place backup and version control of dotfiles.

* Every effort is made to maintain a reproducible GNU/Linux system that can be synchronized between various machines.
* Use of local, user-specific dotfiles that don't touch system defaults are preferred.
	* _eg. dotfiles in `$HOME` supersede any defaults located in `/etc`, `/usr/share`, etc._

## System-wide Configuration
* System-wide changes that bypass the package manager are avoided when possible.
	* _Necessary system-wide changes are reproduced with `~/.once.d` scripts._
* See [`~/.comforts`](.comforts) for the full list of essential packages.

[scrot]: https://i.imgur.com/0peU7Ia.png
[miku]: https://i.imgur.com/Nr7HV9a.png
