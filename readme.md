# <div align="center">_dotfiles—"atelier"_![shimeji]</div>
<div align="center">
	<img src="https://img.shields.io/github/commit-activity/m/microsounds/atelier?logo=github">
	<img src="https://img.shields.io/github/repo-size/microsounds/atelier?logo=github">
	<a href="https://github.com/microsounds/atelier/actions/workflows/ci.yml"><img src="https://github.com/microsounds/atelier/actions/workflows/ci.yml/badge.svg"></a>
	<br>
	<a href="https://debian.org/distrib/"><img src="https://img.shields.io/badge/Debian-bullseye-%23c70036.svg?logo=debian"></a>
	<a href="https://dwm.suckless.org/"><img src="https://img.shields.io/badge/suckless-dwm-%23224488?logo=suckless"></a>
	<a href="https://nano-editor.org/"><img src="https://shields.io/badge/Editor-GNU%20nano-%23440077?logo=windows-terminal"></a>
	<a href="https://www.youtube.com/watch?v=UL8IpdFGeHU"><img src="https://img.shields.io/badge/theme-night drive-%2363B0B0?logo=github-sponsors"></a>
</div>

This is my primary computing setup, a self-contained graphical shell environment for Debian GNU/Linux.
* Git is used to maintain an identical and reproducible setup across multiple machines.
* A series of post-install scripts in [`~/.once.d`](.once.d) document and reproduce system-wide deviations from a fresh install.
	* _Unit testing ensures a reproducible installation with each new change to post-install scripts._

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
	$ git clone --bare {GIT_REMOTE}/atelier ~/.config/meta
	$ git --git-dir=$HOME/.config/meta --work-tree=$HOME reset --hard
	# Invoke the login shell to apply changes made to the environment
	$ exec $SHELL -l
	```
4. Run `post-install` in the shell to run post-install scripts automatically.
	* _Sets up the package manager, installs essential packages, compiles the window manager, etc._
5. Reboot to finish.
	* _[`xinit`](.xinitrc) starts automatically upon login to [`tty1`](.profile)._

## Quick start on Termux for Android
Currently, only a basic shell environment in single-user mode is supported.
1. Install `git`, and bootstrap the system using `git reset --hard` as described above.
2. Post-install: Run only `~/.once.d/a0-android-termux.sh` to apply android-specific hacks and terminal emulator theming.

# Usage notes
## Using `git meta`
For local-scope changes, files in `$HOME` are versioned and mangled in place using Git.
* `$HOME` is considered the detached working tree for a git **bare repo** located at `~/.config/meta`
* The `meta` alias prefixes all git commands with `--git-dir=$HOME/.config/meta --work-tree=$HOME`
* `meta status` will ignore files not manually added or tracked by this git repo.
* Invoking `git` outside of a valid git directory will append the `meta` alias automatically.
	* _`init` and `clone` commands are unaffected._

## Using `~/.once.d` post-install scripts
All system-wide changes are performed through automated scripts located in [`~/.once.d`](.once.d), you can run them all at once with shell function `post-install`. Each script is self-contained, you can run them individually, anytime.

* Some scripts only apply to specific hardware configurations, and will exit even if they are run.
* Scripts affecting `systemd` or the bootloader will be skipped in virtualized container contexts.
* Sideloaded software is installed to [`~/.local/bin`](.local/bin) when possible.
* [`~/.comforts-git`](.comforts-git) describes small sideloaded utilities that will be installed automatically at runtime via git.
	* Repos must have a valid makefile install recipe using the `$(PREFIX)` metaphor.
* [`~/.comforts`](.comforts) describes the full list of non-optional package groups that will be installed.
	* Optional package groups are marked with an *asterisk, you will be prompted to approve these at runtime.

| series | function |
| -- | -- |
| `0*` | System-wide changes performed **through** the package manager. |
| `1*` | Changes to [`~/.local`](.local) file hierarchy, such as sideloaded 3rd party software. |
| `2*` | System-wide changes that bypass the package manager, such as changes to `/etc`.<br>_These are hacks._ |
| `c*` | System-wide changes affecting chromebook hardware only. |
| `a*` | Android-specific hacks only. |

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
| | launcher | p |
| | file manager | e |
| reboot | shutdown | F1 |
| hibernate | sleep | F2 |
| hibernate + reboot | display off | F3 |
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

| alt gr + | key | remarks |
| --: | :-- | :-- |
| prior | up | |
| next | down | |
| home | left | |
| end | right | |
| delete | backspace | |
| F11 | delete | same as power key, keystroke repeat not available |

# Some environment notes
## X server invocation
No login manager is used, login to `tty1` to start the graphical shell.
All daemons and services required to support the graphical shell are initialized along with the X server and are terminated when the user terminates the session.

`systemd` unit services, cronjobs and similar mechanisms are avoided.

At startup, `startx` will pass hardware-specific `xorg.conf` files to the X server, to enable hardware compositing on supported hardware and eliminate screen tearing.

Xorg's security model forbids non-root users from passing arbitrary config files to the X server unless they are located in one of several "blessed" directories.
Post-install scripts will create symlink `/etc/X11/$(id -u)-override` that points to `~/.config/xorg` to override this behavior.

## Optional X Window configuration
### `~/.xrandr`
For use with multi-monitor and/or complicated display setups, you can override the default display layout with one or more commands to `xrandr` saved to _optional_ config file `~/.xrandr`

```
# two monitors, right is vertical
--output HDMI-0 --auto --primary --rotate normal
--output HDMI-1 --auto --right-of HDMI-0 --rotate right
```
Commands in this file are passed to [`xrandr-cycle`](Scripts/xrandr_cycle.sh) line by line at startup if it exists.
For example, this configuration would suit a 2 monitor layout with the right monitor mounted vertically.

### `~/.xdecor`
You can designate one or more paths to directories containing images or videos for use as a wallpaper using _optional_ config file `~/.xdecor`
```
~/Pictures/some/path
/media/sd_card/some/path
```

If it exists, [`xwin-decor`](Scripts/xwin_decor.sh) will randomly pick a directory and file within it and set it as the wallpaper on startup.
In the case of video files, a random video frame from that file will be taken and set as the wallpaper using `ffmpeg`.

## X resources and theming
For consistency, `xinit`, `dwm` and other scripts make use of the C preprocessor to mangle config files and configure color schemes.

Theme settings and indivdual color schemes are stored as C header files containing preprocessor macros representing color hex codes in [`~/.local/include`](.local/include).
This directory is appended to `$C_INCLUDE_PATH` at login.

* Invoking shell function `reload` will reload changes to `.xresources` and refresh your terminal instance.
	* _Optionally, you can temporarily apply another existing color scheme by naming it as an argument._

### List of available macros
* `{FG,BG}COLOR` for terminal fg/bg colors
* `{FG,BG}LIGHT` for UX highlight colors
* `COLOR0..COLOR15` for the 16 standard ANSI terminal colors
* `FN_{TERM,HEADER,TEXT}` for specific font faces
* `FN_{TERM,HEADER}_JP` for matching fallback fonts
* `FN_{TERM,HEADER,TEXT}_SIZE` for matching font sizes

## Non-standard commands
Several commands are extended to include impure functions, such as purposefully mangling config files, and have the following precedence when multiple versions exist:

1. Interactive shell functions defined in [`~/.bashrc`](.bashrc)
2. Executables and symlinks in `~/.local/bin`
	* Some are shell functions promoted to scripts so they'll work in `dmenu` or outside of a terminal context.
3. `/usr/bin` system executables

## `cd`
* The contents of `$OLDPWD` is preserved between sessions.
* `cd` offers the following extensions:

	| opt | function |
	| -- | -- |
	| `...`, `....`, etc. | Shorthand for `../../`, `../../../` and so on. |
	| `-e <dirname>` | Fuzzy find and jump into a sub-directory. |

## `nano`
* `nano` is an alias for [`nano-overlay`](Scripts/nano_overlay.sh) which mangles config files and offers the following extensions:

	| opt | function |
	| -- | -- |
	| `-e, --ctags`<br>`<tag> <#>`  | Jumps into file containing `ctags` definition matching `<tag>`.<br>Optional `<#>` selects from multiple matches, `all` will open all of them. |
	| `-f, --encrypt`<br>`<file>` | Opens a password-protected plaintext file using AES encryption only. <br>File will be created if it doesn't exist. |
	| `-j, --rsa`<br>`<file>` | Opens an SSH RSA key pair-protected plaintext file using RSA+AES encryption. <br>File will be created if it doesn't exist. |

[scrot]: https://github.com/microsounds/microsounds/raw/master/dotfiles/scrot.png
[shimeji]: https://github.com/microsounds/microsounds/raw/master/dotfiles/shimeji.png
