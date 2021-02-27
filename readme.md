# _dotfiles—atelier_![shimeji]
This is my primary computing setup, a self-contained graphical shell environment for Debian GNU/Linux.
* Git is used to maintain an identical and reproducible setup across multiple machines.
* A series of post-install scripts in [`~/.once.d`](.once.d) document and reproduce system-wide deviations from a fresh install.

Basic installation instructions are provided, along with some documentation for the most essential components.

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
For local-scope changes, files in `$HOME` are versioned and mangled in place using Git.
* `$HOME` is considered the detached working tree for the git **bare repo** located in `~/.config/meta`.
* The `meta` alias prefixes git commands with `--git-dir=$HOME/.config/meta --work-tree=$HOME`
* `meta status` will ignore files not manually added or tracked by this git repo.
* Invoking `git` outside of a valid git directory will append the `meta` alias automatically.
	* _`init` and `clone` commands are unaffected._

## Using `~/.once.d` post-install scripts
All system-wide changes are performed through automated scripts located in [`~/.once.d`](.once.d), you can run them all at once with shell function `post-install`.

_You can re-run them anytime without ill effects, some scripts apply only to specific hardware, they will **NOT** touch the system even if they are run._

* System-wide changes that require root access are avoided as much as possible, as these are hacks.
* Sideloaded software is installed to [`~/.local/bin`](.local/bin) instead of `/usr/local/bin`
* [`~/.comforts`](.comforts) descrbes the full list of non-optional package groups that will be installed.
	* Optional package groups are marked with an asterisk, you will be asked to approve these at runtime.

| series | function |
| -- | -- |
| `0*` | System-wide changes performed **through** the package manager. |
| `1*` | Changes to [`~/.local`](.local) file hierarchy, such as sideloaded 3rd party software. |
| `2*` | System-wide changes that bypass the package manager, such as changes to `/etc`.<br>_These are considered unsightly hacks._ |

## Window manager
`dwm` keybinds are the [defaults](https://ratfactor.com/dwm) with several exceptions.
Primary modkey `Mod1` is super instead of alt.

| shift + | alt + | key |
| --: | --: | :-- |
| | kill window | F4 |
| counter-clockwise | switch focused window | tab |
| **shift +** | **super +** | **key** |
| float window<sup>[toggle]</sup> | monocle window<sup>[toggle]</sup> | space |
| set as master window<sup>[toggle]</sup> | terminal | return |
| | file manager | e |
| reboot | shutdown | F1 |
| hibernate | sleep | F2 |
| | display off | F3 |
| | calculator | F4 |
| configure displays | switch active display<sup>[toggle]</sup> | F5 |
| minimum brightness | lower brightness 10% | F6 |
| maximum brightness | raise brightness 10% | F7 |
| configure audio | mute<sup>[toggle]</sup> | F8 |
| | lower volume 5% | F9 |
| | raise volume 5% | F10 |
| | randomize wallpaper | F11 |
| | _reserved_ | F12 |

### Reduced layout for Chromebooks
Search/Everything/Caps lock key serves as the super key. Same as above, with the following changes:

| shift + | alt gr + | key |
| --: | --: | :-- |
|| prior | up |
|| next | down |
|| home | left |
|| end | right |
| _disabled_ | _disabled_ | power |
|| delete | backspace |

# Some environment notes
## X server invocation
No login manager is used, login to `tty1` to start the graphical shell.
All daemons and services required to support the graphical shell are initialized along with the X server and are terminated when the user terminates the session.

`systemd` unit services, cronjobs and similar mechanisms are avoided.

At startup, `startx` will pass hardware-specific `xorg.conf` files to the X server, to enable hardware compositing on supported hardware and eliminate screen tearing.

Xorg's security model forbids non-root users from passing arbitrary config files to the X server unless they are located in one of several "blessed" directories.
Post-install scripts will create symlink `/etc/X11/$(id -u)-override` that points to `~/.config/xorg` to override this behavior.

## X resources and color
Both `xrdb` and `dwm` compilation make use of the C preprocessor to configure color schemes.

Individual color schemes are stored as C header files containing preprocessor macros representing color hex codes in [`~/.local/include`](.local/include). This directory is appended to `$C_INCLUDE_PATH` at login.

* [`.xresources`](.xresources), [scripts](Scripts/xwin_decor.sh) and [C source code](.config/dwm/config.h) can `#include <colors/example.h>` to reference color macros
	* `{FG,BG}COLOR` for terminal fg/bg colors
	* `{FG,BG}LIGHT` for UX highlight colors
	* `COLOR0..COLOR15` for the 16 standard ANSI terminal colors
* Invoking shell function `reload` will reload changes to `.xresources` and refresh your terminal instance.
	* _Optionally, you can temporarily apply another existing color scheme by naming it as an argument._

## X root window decoration
Using _optional_ config file `~/.xdecor`, you can designate an absolute path to a directory containing videos or images to use as a wallpaper.
```
$ pwd > ~/.xdecor
```
If configured, [`xwin_decor`](Scripts/xwin_decor.sh) will pick a random file within it and set it as the wallpaper on startup.
In the case of video files, a random video frame from that file will be taken and set as the wallpaper using `ffmpeg`.

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
* Invoking `nano` calls a shell function which generates customized syntax files for some C-like languages.
* Arguments are passed verbatim to [`nano_overlay`](Scripts/nano_overlay.sh) which mangles config files and offers the following extensions:

	| opt | function |
	| -- | -- |
	| `-e, --ctags`<br>`<tag> <#>`  | Jumps into file containing `ctags` definition matching `<tag>`.<br>Optional `<#>` selects from multiple matches, `all` will open all of them. |
	| `-f, --encrypt`<br>`<file>` | Opens a password-protected plaintext file packed using `xz \| openssl`.<br>File will be created if it doesn't exist. |

[scrot]: https://github.com/microsounds/microsounds/raw/master/dotfiles/scrot.png
[shimeji]: https://github.com/microsounds/microsounds/raw/master/dotfiles/shimeji.png
