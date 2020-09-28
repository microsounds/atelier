# _dotfiles—atelier_![shimeji]
_Dotfiles, shell scripts, complete graphical/shell configuration for Debian GNU/Linux, home directory backup._
![scrot]
> _Pictured: Debian stable, POSIX shell scripts, urxvt, and Xorg + dwm + sxhkd as a graphical shell_

# Quick start
1. Install Debian stable, perform a base install with no DE selected and no standard utilities when prompted.
	* _Do not perform these steps on `tty1`, `xinit` will launch without `dwm` present and you will be booted._
2. Install `git`, `wget`, and `sudo`, then add yourself to the `sudo` group.
	* Log back in to reflect changes to group membership.
3. Bootstrap the system automatically with a hard git reset from this repo, this is done only once.
	```shell
	$ git clone --bare [remote] ~/.config/meta
	$ git --git-dir=$HOME/.config/meta --work-tree=$HOME reset --hard
	# Invoke the login shell to reflect all changes to the environment
	$ exec $SHELL -l
	```
4. `for f in ~/.once.d/*; do $f; done` to run post-install scripts.
	* _Sets up the package manager, installs essential packages, compiles the window manager, etc._
5. Reboot to finish.
	* _[`xinit`](.xinitrc) starts automatically upon login to [`tty1`](.profile)._

# Usage notes
## Using `git meta`
For the purposes of version control, `$HOME` is treated as the detached working tree for the git **bare repo** located in `~/.config/meta`

* `meta` prefixes git commands with `--git-dir=$HOME/.config/meta --work-tree=$HOME`
* `meta status` will ignore files not tracked by this git repo.
* Invoking `git` outside of a valid git directory will append the `meta` alias automatically.
	* `init` and `clone` commands are unaffected.

This is ideal for changes within the home directory, but not for system-wide changes.

## Using `~/.once.d` post-install scripts
All system-wide changes are performed through automated scripts located in [`~/.once.d`](.once.d)

_Some scripts apply only to specific hardware, they will **NOT** touch the system even if they are run._

* System-wide changes that require root access are avoided as much as possible, as these are usually hacks.
* Sideloaded software is installed to [`~/.local/bin`](.local/bin) instead of `/usr/local/bin`
* [`~/.comforts`](.comforts) descrbes the full list of non-optional package groups that will be installed.
	* Optional package groups are marked with an asterisk, you will be asked to approve these at runtime.

| series | function |
| -- | -- |
| `0*` | System-wide changes performed **through** the package manager, eg. installing packages from Debian repos. |
| `1*` | Changes to [`~/.local`](.local) file hierarchy, eg. sideloading 3rd party software. |
| `2*` | System-wide changes that purposefully defeat the package manager, eg. changes to `/etc`. These are hacks. |

# Some environment notes
## Use of daemons
All daemons and services required to support the graphical shell are initialized during X startup and terminated when the user logs out.

`systemd` unit services, cronjobs and similar mechanisms are avoided.

## Non-standard commands
Several commands are extended to include impure functions, such as purposefully mangling config files, and have the following precedence when multiple versions exist:

1. Interactive shell functions defined in [`~/.bashrc`](.bashrc)
2. Scripts and symlinks in `~/.local/bin`
	* Some are shell functions posing as scripts so they'll work in `dmenu` and external scripts.
3. `/usr/bin` system executables

## `startx`
Invoking `startx` will pass hardware-specific `xorg.conf` files to the X server, mostly for screen tearing fixes.

Xorg's security model forbids non-root users from passing arbitrary config files to the X server unless they are located in one of several "blessed" directories.
Post-install scripts will create symlink `/etc/X11/$(id -u)-override` that points to `~/.config/xorg` to override this behavior.

## `cd`
* The contents of `$OLDPWD` is preserved between sessions.
* `cd` offers the following extensions:
	| opt | function |
	| -- | -- |
	| `...`, `....`, etc. | Shorthand for `../../`, `../../../` and so on. |
	| `-e <dirname>` | Fuzzy find and jump into a sub-directory. |

## `nano`
* Invoking `nano` calls a shell function which generates customized syntax files for C-like languages.
* Arguments are passed verbatim to [`nano_overlay`](Scripts/nano_overlay.sh) which mangles config files and offers the following extensions:
	| opt | function |
	| -- | -- |
	| `-f <file>` | Opens `xz \| openssl` encrypted files. |
	| `-e <tag>`  | Looks for a `ctags` index file, jumps to file containing tag definition. |

[scrot]: https://github.com/microsounds/microsounds/raw/master/dotfiles/scrot.png
[shimeji]: https://github.com/microsounds/microsounds/raw/master/dotfiles/shimeji.png
