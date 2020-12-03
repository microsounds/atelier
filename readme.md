# _dotfiles—atelier_![shimeji]
This is my primary computing setup, a self-contained graphical shell environment for Debian GNU/Linux.
* Git is used to maintain an identical and reproducible setup across multiple machines.
* A series of post-install scripts in [`~/.once.d`](.once.d) document and reproduce system-wide deviations from a fresh install.

Some installation instructions are provided, along with documentation for some of the more arduous parts.

![scrot]
> _Pictured: Debian stable, a "graphical shell" environment consisting mostly of Xorg, dwm, sxhkd, and urxvtd._

# Quick start
1. Install Debian stable, perform a base install with no DE selected and no standard utilities when prompted.
	* _Do not perform these steps on `tty1`, `xinit` will launch without `dwm` present and you will be booted._
2. Install `git`, `wget`, and `sudo`, then add yourself to the `sudo` group.
	* Log back in to apply changes to group membership.
3. Bootstrap the system automatically with a hard git reset from this repo, this is done only once.
	```shell
	$ git clone --bare [remote] ~/.config/meta
	$ git --git-dir=$HOME/.config/meta --work-tree=$HOME reset --hard
	# Invoke the login shell to apply changes made to the environment
	$ exec $SHELL -l
	```
4. Run `post-install` in the shell to run post-install scripts automatically.
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
All system-wide changes are performed through automated scripts located in [`~/.once.d`](.once.d), you can run them all at once with shell function `post-install`.

_You can re-run them anytime without ill effects, some scripts apply only to specific hardware, they will **NOT** touch the system even if they are run._

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
## X server invocation
No login manager is used, login to `tty1` to start the graphical shell.
All daemons and services required to support the graphical shell are initialized along with the X server and are terminated when the user terminates the session.

`systemd` unit services, cronjobs and similar mechanisms are avoided.

At startup, `startx` will pass hardware-specific `xorg.conf` files to the X server, to enable hardware compositing on supported hardware and eliminate screen tearing.

Xorg's security model forbids non-root users from passing arbitrary config files to the X server unless they are located in one of several "blessed" directories.
Post-install scripts will create symlink `/etc/X11/$(id -u)-override` that points to `~/.config/xorg` to override this behavior.

## Non-standard commands
Several commands are extended to include impure functions, such as purposefully mangling config files, and have the following precedence when multiple versions exist:

1. Interactive shell functions defined in [`~/.bashrc`](.bashrc)
2. Scripts and symlinks in `~/.local/bin`
	* Some are shell functions posing as scripts so they'll work in `dmenu` and external scripts.
3. `/usr/bin` system executables

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
