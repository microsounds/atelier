<!-- header and github badges -->
<!-- github readmes only support align attributes for styling -->
<div align="center">

# _dotfiles—"atelier"_![shimeji]
![ico-freq](https://img.shields.io/github/commit-activity/m/microsounds/atelier?logo=github)
![ico-size](https://img.shields.io/github/repo-size/microsounds/atelier?logo=github)
[![ico-ci](https://github.com/microsounds/atelier/actions/workflows/ci.yml/badge.svg)][actions]
<br/>
[![ico-os](https://img.shields.io/badge/Debian-bookworm-%23c70036.svg?logo=debian)][debian]
[![ico-wm](https://img.shields.io/badge/suckless-dwm-%23224488?logo=suckless)][dwm]
[![ico-editor](https://shields.io/badge/Editor-GNU%20nano-%23440077?logo=windows-terminal)][nano]
[![ico-theme](https://img.shields.io/badge/theme-night%20drive-%2363B0B0?logo=github-sponsors)][song]
<br/>
<sup>_shimeji miku [&copy; 2010 canary yellow][miku]_</sup>
</div>

[actions]: https://github.com/microsounds/atelier/actions/workflows/ci.yml "unit tests"
[debian]: https://debian.org/distrib/ "Debian GNU/Linux homepage"
[dwm]: https://dwm.suckless.org/ "suckless dwm homepage"
[nano]: https://nano-editor.org/ "GNU nano homepage"
[song]: https://www.youtube.com/watch?v=UL8IpdFGeHU "effe - night drive ft. 初音ミク"
[miku]: http://canarypop.ciao.jp/shimehatsune.htm "Shimeji Miku homepage"

<!-- start of document -->

This is my primary computing setup, a self-contained graphical shell environment for Debian GNU/Linux.
* Git is used to maintain an identical and reproducible setup across multiple machines.
* A series of post-install scripts in [`~/.once.d`](.once.d) document and reproduce system-wide deviations from a fresh install.
	* _A [suite of unit tests](.github/workflows/ci.yml) ensures a reproducible installation with each revision._

Detailed installation instructions are provided, along with some documentation for the most essential components.

<!-- figure 1: desktop screenshot -->
[![scrot]][scrot]
_Pictured: Debian stable, a "graphical shell" environment consisting mostly of xorg, dwm, sxhkd and various urxvt clients._

# Quick start
<details style="background-color: #0000001C; padding: 3px;">
<summary><strong>[OPTIONAL] Instructions for a Debian base install with <code>debootstrap</code> for BIOS/UEFI x86 systems.</strong></summary>

## Installing Debian using `debootstrap`
> **WARNING**<br/>
> _This is a quick reference on using `debootstrap` to install Debian manually without using the official Debian installer.
> This is not a comprehensive tutorial on *NIX concepts, you should have some familiarity with administrating a GNU/Linux system before continuing._

1. Boot into a Debian Live CD environment with any DE and partition your boot disk with `gparted`.

	You should always keep a Live CD install media around for use as a rescue disk, regardless of installation method.
	I only do it this way because I don't feel like using `fdisk`.

	_To install packages in the live environment, `apt-get update` first and then `apt-get install gparted`._

	Suggested boot disk layouts:
	* Legacy BIOS systems that support MBR/`msdos` partition tables
	```
	# MBR disks support a maximum of 4 primary partitions
	[ primary part. (root) ] [ extended partition                            ]
	                         [ logical part. (swap) ] [ logical part. (home) ]
	# example /etc/fstab
	/dev/sda1	/       ext4	defaults	0	1
	/dev/sda5	none    swap	defaults	0	0
	/dev/sda6	/home   ext4	defaults	0	2
	```

	* Modern UEFI systems that support GPT/`gpt` partition tables
	```
	# EFI partition must be FAT32 and at least 32MiB
	[ EFI partition ] [ root partition ] [ swap partition ] [ home partition ]

	# example /etc/fstab
	/dev/sda1	/boot/efi   vfat	defaults	0	2
	/dev/sda2	/           ext4	defaults	0	1
	/dev/sda3	none        swap	defaults	0	0
	/dev/sda3	/home       ext4	defaults	0	2
	```

	> **NOTE**<br/>
	> _If your machine uses a slow eMMC-based boot disk, I recommend `f2fs` for modestly improved performance instead of `ext4`.
	> Support for booting from `f2fs` is not provided by default in Debian.<br/>
	> See [this tutorial][f2fs] on adding required `f2fs` modules to `initramfs` for more info._

	[f2fs]: https://howtos.davidsebek.com/debian-f2fs.html#:~:text=Booting%20From%20F2FS
		"Install Debian 10 Buster on an F2FS Partition"

2. Mount your newly created filesystem in `/mnt`, including your home partition to `/mnt/home` if you made one.
3. Install `debootstrap` and install the Debian base system into `/mnt`.
	* `debootstrap --arch [eg. i386, amd64] stable /mnt https://deb.debian.org/debian`
		* _See <https://www.debian.org/ports/> for a full list of platforms available._
4. Chroot into your new system, _all actions from this point onward are within your chrooted system_.
	```sh
	$ sudo su -
	$ for f in proc sys dev run; do mount --make-rslave --rbind /$f /mnt/$f; done
	$ chroot /mnt /bin/bash
	```
5. Configure your `/etc/fstab` to taste.
	* Try `lsblk -f >> /etc/fstab` to identify disks by `UUID=...` instead of device name.
6. Customize your locale by installing and `dpkg-reconfigure`'ng `locales`, and `tzdata`.
7. Edit `/etc/hostname` and `/etc/hosts` with your preferred hostname.
8. Install a suitable linux kernel.
	* Find a suitable kernel meta-package to install with `apt-cache search ^linux-image | grep 'meta'`.
9. Install `network-manager` and the bootloader package `grub2`.

	`grub2` does not install to your boot disk automatically, use the following:
	* Build initial grub configuration with `/sbin/update-grub`
	* For BIOS (installs to magic sector at start of disk)
		* `/sbin/grub-install --root-directory=/ /dev/sda`
	* For UEFI (installs to EFI partition mounted in `/boot/efi`)
		* `/sbin/grub-install --root-directory=/ --efi-directory=/boot/efi /dev/sda`
10. Give your `root` user a password, create your normal user, and assign it a password also.
	* eg. `useradd -m USERNAME -s /bin/bash; passwd USERNAME`
11. You should now have a working system, **login as your user** and skip to Step 2 in the **Quick start** below.
	* _You can reboot from the Live CD environment at this point to check your work but it's not required._

</details>

1. Install Debian stable, perform a base install with no DE selected and no standard utilities when prompted.
	* _Do not perform these steps on `tty1`, `xinit` will launch without `dwm` present and you will be kicked._
2. Install `git`, `wget`, and `sudo`, then add yourself to the `sudo` group.
	* Log back in to apply changes to group membership.
3. Bootstrap the system automatically with a hard git reset from this repo, this is done only once.
	```shell
	$ git clone --bare {GIT_REMOTE}/atelier ~/.config/meta
	$ git --git-dir=$HOME/.config/meta --work-tree=$HOME reset --hard
	# Invoke the login shell to apply changes made to the environment
	$ exec $SHELL -l
	```
4. Run `post-install` in the shell to run post-install scripts automatically. Do not run as root.
	* _Sets up the package manager, installs essential packages, window manager, text editor, etc._
5. Reboot to finish.
	* _[`xinit`](.xinitrc) starts automatically upon login to [`tty1`](.profile)._

<!-- figure 2: mobile screenshot -->
<span style="float: right;">
<a href="https://raw.githubusercontent.com/microsounds/microsounds/master/dotfiles/mobile-scrot.jpg">
<img alt="mobile scrot" width="125" align="right"
	src="https://raw.githubusercontent.com/microsounds/microsounds/master/dotfiles/mobile-scrot2.png"/>
</a>
</span>

## Quick start on Termux for Android
> **NOTE**<br/>
> _Android-specific functionality depends on features provided by `Termux:API` and `Termux:Widget` add-on apps and must be installed along with Termux.<br/>
> This is meant to be a lightweight port with modifications, do not initiate a full `post-install`._

1. Install `git`, and bootstrap the system using `git reset --hard` as described above.
2. Post-install: Run only [`~/.once.d/a0-android-termux.sh`](.once.d/a0-android-termux.sh)
	* Applies android-specific hacks and termux specific dotfiles for theming and softkeys.
3. When pulling from upstream, stash changes or `git reset --hard` to prevent merge conflicts.
	* Use `patch -p1 < ~/.termux/diff.patch` to restore changes if stash is lost.

See [attached notes](#Termux-for-Android) for overview of changes from a standard Linux environment.

## List of supported platforms
**Full graphical shell environment**
* Any conventional BIOS/UEFI-compliant x86-based Personal Computer
* x86-based Chromebooks in Developer Mode (SeaBIOS), or liberated with UEFI firmware (Coreboot).
	* _See <https://chrultrabook.github.io/docs/> for more information on unlocking your bootloader._
* [Next Thing Co. PocketC.H.I.P][ntc-chip] armhf-based portable ~~toy computer~~ linux handheld
	* _Final NTC-provided Debian 8 (jessie) OS images from 2016 come with out-of-tree `4.4.13-ntc-mlc` kernel pinned, upgradeable to 10 (buster)._

[ntc-chip]: http://chip.jfpossibilities.com/docs/pocketchip.html "Mirrored PocketCHIP documentation"

**Single-user minimal shell environment**
* Bootstrapping in virtualized container instances for use in CI/CD workflows
* Termux terminal emulator and Linux environment for Android
	* _Non-standard *NIX environment, currently only supports a subset of available features._

# Usage notes
## Using `git meta`
For local-scope changes, files in `$HOME` are versioned and mangled in place using Git.
* `$HOME` is treated as the detached working tree for a git **bare repo** located at `~/.config/meta`
* The `meta` alias prefixes all git commands with `--git-dir=$HOME/.config/meta --work-tree=$HOME`
* `meta status` will ignore files not manually added or tracked by this git repo.
	* _This is achieved using the `status.showUntrackedFiles` option and not via manually updating `~/.gitignore` as is commonly done._
* Invoking `git` outside of a valid git directory will append the `meta` alias automatically.
	* _`init` and `clone` commands are unaffected._

## Using `~/.once.d` post-install scripts
All system-wide changes are performed through automated scripts located in [`~/.once.d`](.once.d), you can run them all at once with shell function `post-install`.
Each script is self-contained, you can run them individually, anytime.

* Some scripts apply only to specific hardware configurations, and will exit even if they are run.
* Scripts affecting `systemd` or the bootloader will be skipped in virtualized container contexts.
* Locally installed software is installed to [`~/.local/bin`](.local/bin) when possible.

| series | function |
| -- | -- |
| `0*` | System-wide changes performed through the package manager. |
| `1*` | Changes to [`~/.local`](.local) file hierarchy, such as locally installed software and resources. |
| `2*` | System-wide changes that bypass the package manager, such as changes to `/etc`.<br/>_These are hacks._ |
| `c*` | System-wide changes affecting chromebook hardware only. |
| `a*` | Android-specific hacks only. |
| `p*` | NTC PocketCHIP-specific hacks only. |

### Essential and *optional package groups
* [ `~/.comforts` ](.comforts) describes a list of non-optional package groups that will be installed through the package manager.
	* _Optional package groups are marked with an *asterisk, you will be prompted to approve these at runtime._

### Essential and *persistent upstream utilities
* [`~/.comforts-git`](.comforts-git) describes the full list of utilities compiled and installed from their upstream git sources.
	* _Repos must have a typical `./configure` and/or `make install PREFIX=...` metaphor to build correctly._
	* _Sources marked with an *asterisk will be persistently installed to `~/.config/${URL##*/}`_

Installation can be customized with user-provided executable install ~~hacks~~ scripts, named `{pre,post}-run`.
These can be placed in [`~/.config/upstream`](.config/upstream) or at the root of a persistently installed utility's install directory as described above

Rationale for doing things this way is summarized in commit [`2fe1c3745`][rat].

[rat]: https://github.com/microsounds/atelier/commit/2fe1c3745 "introduced ~/.once.d/10-git-upstream.sh"

## Window manager
Keyboard layouts and secondary layers are handled by `keyd` globally for better quality of life on non-standard keyboards.
At the X server level, keybinds are handled by a mix of ~~`xkb`~~, `dwm`, `sxhkd` and `fcitx5` in such a way to avoid keybind stomping.

`Caps Lock` is remapped to `Super_L` on all platforms.
`dwm` keybinds are the [defaults][dwm] with several exceptions, the modkey `Mod1` is **super** instead of **alt** because many **alt** combinations are already taken by other applications I use.

[dwm]: https://ratfactor.com/dwm "suckless dwm tutorial"

**Alt**-based keybinds are kept to a minimum because these are commonly taken by applications.

| shift + | alt + | key |
| --: | --: | :-- |
| | kill window | F4 |
| counter-clockwise | switch focused window | tab |

**Super**-based keybinds meant for system and window manager functions.

| shift + | super + | key |
| --: | --: | :-- |
| float window<sup>[toggle]</sup> | monocle window<sup>[toggle]</sup> | space |
| set as master window<sup>[toggle]</sup> | terminal | return |
| | launcher | p |
| | file manager | e |
| | ssh-add<sup>[toggle]</sup> | backspace |
| partial screenshot | screenshot | print |
| | _reserved_ | scroll lock |
| | _reserved_ | pause |
| reboot | shutdown | F1 |
| hibernate | sleep | F2 |
| hibernate + reboot | display off | F3 |
| configure networking | calculator | F4 |
| configure displays | switch active display<sup>[toggle]</sup> | F5 |
| minimum brightness | lower brightness 10% | F6 |
| maximum brightness | raise brightness 10% | F7 |
| configure audio | mute<sup>[toggle]</sup> | F8 |
| | lower volume 5% | F9 |
| | raise volume 5% | F10 |
| | randomize wallpaper | F11 |
| | _reserved_ | F12~F24 |

**Special** keybinds that don't fit in other categories.

| alt + | ctrl + | key<sup>[special]</sup> |
| --: | --: | :-- |
| | switch input method<sup>[toggle]</sup> | space |
| | clipboard manager | ; |
| task manager | | delete |
| syslog | | insert |

### Generic 74-key Chromebook layout
Search key is `Super_L`, most missing keys are hidden behind `Right Alt` layer.
Power key has been remapped to `delete` for better usability.

Function `F1-F10` are in the usual places, F11 is lesser used and hidden behind `Right Alt`.
| right alt + | key | remarks |
| --: | :-- | :-- |
| prior | up | |
| next | down | |
| home | left | |
| end | right | |
| XF86Back | F1 | _Right Alt + F* may not work on pre-EC chromebooks_ |
| XF86Forward | F2 | |
| XF86Reload |  F3 | |
| F11 | F4 | opens fullscreen mode in most browsers |
| XF86LaunchA | F5 |
| lower brightness 10%  | F6 | |
| raise brightness 10%  | F7 | |
| mute<sup>[toggle]</sup> | F8 | |
| lower volume 5% | F9 | |
| raise volume 5% | F10 | |
| F11 | delete | same as power key, keystroke repeat not available |
| delete | backspace | keystroke repeat works fine |

# Some environment notes
## X server invocation
No display manager is used, login to `tty1` to start the graphical shell.

All daemons and services required to support the graphical shell are initialized along with the X server and are terminated when the user terminates the session.

`systemd` unit services, cronjobs and similar mechanisms are avoided whenever possible.

At startup, `startx` will pass hardware-specific `xorg.conf` files to the X server, to enable hardware compositing on supported hardware and eliminate screen tearing.

Xorg's security model forbids non-root users from passing arbitrary config files to the X server unless said configs are located in one of several "blessed" directories.
Post-install scripts will create symlink `/etc/X11/$(id -u)-override` that points to `~/.config/xorg` to override this behavior.

## Optional X Window configuration
### `~/.xrandr`
For use with multi-monitor and/or complicated display setups, you can override the default display layout with one or more commands to `xrandr` saved to _optional_ config file `~/.xrandr`

	# e.g. two monitors, right is mounted vertically
	--output HDMI-0 --auto --primary --rotate normal
	--output HDMI-1 --auto --right-of HDMI-0 --rotate right

Commands in this file are passed to [`xrandr-cycle`](Scripts/xrandr_cycle.sh) line by line at startup if it exists.
For example, this configuration would suit a 2 monitor layout with the right monitor mounted vertically.

### `~/.xdecor`
You can designate one or more paths to directories containing images or videos for use as a wallpaper using _optional_ config file `~/.xdecor`

	# prefixing with ~/ is acceptable
	~/Pictures/some/path
	/media/sd_card/some/path

If it exists, [`xwin-decor`](Scripts/xwin_decor.sh) will randomly pick a directory and file within it and set it as the wallpaper on startup.
In the case of video files, a random video frame from that file will be taken and set as the wallpaper using `ffmpeg`.

## X resources and theming
For consistency, `xinit`, `dwm` and other scripts make use of the C preprocessor to mangle config files and configure color schemes.

Theme settings and individual color schemes are stored as C header files containing preprocessor macros representing color hex codes in [`~/.local/include`](.local/include).
This directory is appended to `$C_INCLUDE_PATH` at login.

* Using shell function `reload` will reload changes to `.xresources` and hard-reset your current terminal instance.
* Use command `palette` to soft-reset color scheme using OSC terminal escapes without losing the current shell.

_Optionally, you can apply another existing color scheme by naming it as an argument.
This can be useful when dealing with TUI applications that force their own background colors._

### List of available macros
* `{FG,BG}COLOR` for terminal fg/bg colors
* `{FG,BG}LIGHT` for UX highlight colors
* `COLOR0..COLOR15` for the 16 standard ANSI terminal colors
* `FN_{TERM,HEADER,TEXT}` for specific font faces
* `FN_{TERM,HEADER}_JP` for matching fallback fonts
* `FN_{TERM,HEADER,TEXT}_SIZE` for matching font sizes
* `FN_EMOJI` for specifying fallback emoji glyphs
* `FN_EMOJI_SIZE` for specifying fallback emoji glyph sizes

## Issues with HiDPI scaling
HiDPI display setups are currently **not** supported, 96dpi is assumed everywhere.

HiDPI scaling brings up innumerable display issues in [every category of graphical software][dpi1]
including [electron-based applications][dpi2] that require polluting scripts and dotfiles to smooth out toolkit scaling issues.
Maintaining mixed-DPI multi-monitor setups in X11 is [even more painful][dpi3].

As of posting, I don't have a >1080p monitor to motivate such changes,
I'm not about to pepper my scripts with toolkit-specific environment variables and conditional logic to support HiDPI scaling.
See [`~/.local/include/theme.h`](.local/include/theme.h) for more info.

[dpi1]: https://wiki.archlinux.org/title/HiDPI "A laundry list of hacks to have consistent-looking fonts everywhere under HiDPI"
[dpi2]: https://blog.yossarian.net/2020/12/24/A-few-HiDPI-tricks-for-Linux "The real HiDPI experience on GNU/Linux"
[dpi3]: http://wok.oblomov.eu/tecnologia/mixed-dpi-x11/#mixeddpiinx11 "Workarounds for mixed DPI multi-monitor setups in X11"

# Non-standard commands
Several commands are extended to include impure functions, such as purposefully mangling config files, and have the following precedence when multiple versions exist:

1. Interactive shell functions defined in [`~/.bashrc`](.bashrc)
2. Non-interactive shell library executables in [`~/.local/lib`](.local/lib)
	* Shell script snippets used by multiple scripts to reduce clutter.
3. Normal executables and symlinks in [`~/.local/bin`](.local/bin)
	* Some are shell functions promoted to scripts so they'll work in `dmenu` or outside of a terminal context.
4. `/usr/bin` system-wide executables

## Interactive shell
![path-gitstatus](https://raw.githubusercontent.com/microsounds/microsounds/master/dotfiles/path-gitstatus.png)

The prompt path will feature embedded `git` information provided by [`path-gitstatus`](Scripts/git_status.sh) highlighting the root of a `git` worktree and it's status.

Outside of `git` worktrees, the path component will be mangled by [`path-shorthand`](.local/lib/path-shorthand) and be truncated to the last `$PATH_WIDTH` characters _(default is 50)_ for improved usability.

## Termux for Android
Single-user shell environment should work as expected on Termux without root access or changes to `$PREFIX/etc` with several caveats described below.

Post-install scripts make the following adjustments statically for existing scripts.
These adjustments will also be saved as a diff patch in `~/.termux/diff.patch` in case these changes are overwritten with `git`.

### `Termux:Widget`
Scripts in [`~/.shortcuts`](.shortcuts) are meant for use with `Termux:Widget` which can be found wherever you got Termux.
This is an optional add-on to Termux that lets you launch foreground or background scripts from an Android homescreen widget.

See the [project page](https://github.com/termux/termux-widget) for documentation and environment notes, it's important to note that scripts launched this way do not source `~/.profile` or `~/.bashrc` like they would running from a Termux instance.

You must give Termux permission to display over other apps via `Settings > Apps > Display over other apps` for this add-on to work properly.

### Standard file descriptors
Shell scripts on Android systems without root access have no access to standard file descriptors `/dev/std{in,out,err}`, use `/proc/self/fd/{0,1,2}` instead.

### `ESC` sequences
`<backslash>e` to insert escape literals in scripts works for some OSC codes, but not all, use octal `<backslash>33` when in doubt.

### `$PREFIX`
Previously, `termux-chroot` was used to ensure FHS-compliance, but it introduced unacceptable performance speed.

Use Termux's own provided envvar `$PREFIX` to refer to standard filesystem locations within scripts or interactively, e.g. `$PREFIX/tmp` which expands to `/data/data/com.termux/files/usr/tmp`.
In practice, shell script shebangs don't need to be rewritten, Termux already rewrites these with some hidden voodoo I don't care to understand.

### Background processes since Android 11
The customized Android images that ship from [Chinese and Korean manufacturers](https://dontkillmyapp.com/) since version 11 have become far more aggressive in pruning "phantom" processes (daemons) in the pursuit of better battery life.

You may experience issues with processes backgrounded with the `&` operator being throttled or killed when multitasking outside of Termux. _Daemons that fork without becoming a child process or `exec`'ing the same process that called it may be killed immediately or shortly after leaving Termux if not called in foreground mode._

In order to prevent Android from prematurely pruning `ssh-agent` while multitasking, it is called as the parent process for the current shell.

Termux developers recommend their very own [termux-services](https://wiki.termux.com/wiki/Termux-services) for running common daemons.
_Launch daemons in foreground mode without forking and preferably with wakelock acquired from the `Notification Bar` or with `termux-wake-lock` if you wish to run a long-running task without being throttled by the operating system._

If you don't mind the limitations of `Termux:Widget`, you can also run long-running scripts as a headless background tasks by putting it in `~/.shortcuts/tasks`.

### `ssh-agent` fingerprint SSH authentication
> **WARNING** <br/>
> _This is an ongoing experiment in balancing convenience and security, your threat model may find the barebones security provided by fingerprint sensors unacceptable._

`ssh-agent` is set up to call [`termux-ssh-askpass`](.local/lib/termux-ssh-askpass) which uses
Android's [hardware-backed keystore](https://developer.android.com/privacy-and-security/keystore) to generate an OpenSSH key passphrase using the fingerprint lock on your Android device.

Specifically, a hardware-backed inaccessible RSA 4096-bit private key named `default` is generated during post-install
and stored in the security chip on the device which is only made available during a short validity period after a successful fingerprint unlock.
This inaccessible private key is used to sign the matching public key for the portable OpenSSH private key being unlocked by `ssh-agent` and friends
to produce a passphrase from the signed nonce value emitted by the security chip on your Android device.

Simply put, _this allows for fingerprint-based SSH authentication_, a massive quality of life improvement over entering case-sensitive passphrases on a smartphone.

#### Important considerations
1. Both the `termux-api` package and the companion add-on app `Termux:API` available from the same place you got Termux are required for this functionality to work.
2. There is no chance of vendor or device lock-in, as you are not using key material from the security chip as your OpenSSH key.
	* The nonce value is not important, it's just convenient seed data used to produce a reproducible passphrase that requires your fingerprint to unlock.
	* The key material locked in the hardware-backed keystore is also not important, you are simply using it to generate passphrases for your existing portable OpenSSH keys.

3. Even though someone with physical access to your Android device _could_ modify the hardware keystore without authentication and _could_ replace keys with identically named keys that have an unlimited validity period, they will not be the same key material used to sign and your portable OpenSSH keys will still be safe.
4. You understand that by replacing passphrases with biometrics, your fingerprint reader becomes your single point of failure, you have been warned.

#### Initial setup
To setup your existing OpenSSH keys for fingerprint-based SSH authentication, use the output of `termux-ssh-askpass` as your new passphrase in `ssh-keygen`.

```
new_pass="$(termux-ssh-askpass ~/.ssh/id_rsa)"
ssh-keygen -p -f ~/.ssh/id_rsa -N "$new_pass" -F 'old passphrase'
```

## `cd`
* The contents of `$OLDPWD` is preserved across `bash` sessions.
* `cd` offers the following extensions:

	| opt | function |
	| -- | -- |
	| `...`, `....`, etc. | Shorthand for `../../`, `../../../` and so on. |
	| `-f <query>` | Interactive fuzzy find and jump into a sub-directory with `fzf` |

## `chromium`
> **NOTE**<br/>
>_On first-run, `chromium` will momentarily exit and restart to rebuild configuration and enable use of externally customized color options._

`chromium` is not meant to be user-serviceable or configurable through plaintext without using system-wide group policy features, `chromium` is a shell script extended to mangle user-hostile internal state files to match the persistent plaintext configs described below:
* [`~/.config/chromium/preferences.conf`](.config/chromium/preferences.conf)
	* _Main browser preferences stored as JSON in `Default/Preferences`._
* [`~/.config/chromium/local_state.conf`](.config/chromium/local_state.conf)
	* _Chromium experiment flags stored as JSON in `Local State`._

C preprocessor syntax is also accepted, hex color values in the form `#RRGGBB` will be converted to a signed integer representing `0xBBGGRRAA` in two's complement hexadecimal with `AA` (alpha channel) always set to `0xFF`

* [`~/.config/chromium/omnibox.sql`](.config/chromium/omnibox.sql)
	* _Omnibox settings and Tab-to-search keyword shortcuts stored as SQLite in `Default/Web Data`._

### Managed policy overrides
`chromium` is managed by `/etc/chromium/policies/managed/extensions.json`, set up during [post-install](.once.d/29-chromium-extensions.sh), which automatically installs several useful extensions on first-run, including [uBlock Origin][].

[uBlock Origin]: https://ublockorigin.com "uBlock Origin homepage"

### Configuring Vimium
Use of Vimium is considered optional, as I haven't figured out a way to configure it automatically on first-run.
Its configuration resides in [`~/.config/chromium/vimium`](.config/chromium/vimium)

Run `configure.sh` to rebuild `vimium-options.json` for importing back into Vimium by hand.

### An ongoing experiment
`chromium` has proven difficult to configure non-interactively time and time again.
Plaintext `chromium` configuration is an ongoing experiment of mine.

| non-interactive functionality | status |
| -- | :--: |
| first-run config rebuild | works |
| applying persistent chromium settings | works |
| applying persistent chromium flags | works |
| applying persistent omnibox settings | works |
| extension install on first-run | works _(via group policy)_ |
| applying persistent extension settings | **no** |

## `git`
`git` aliases are defined in [`~/.gitconfig`](.gitconfig) or implemented in interactive shell function `git()`

See *Usage Notes* for more information.

* _This is a critical component of the graphic shell environment, some aliases are cumulative in nature._

	| alias | function |
	| -- | -- |
	| `meta` | Appends `--git-dir=$HOME/.config/meta --work-tree=$HOME` to a `git` command.<br/>_(Added implicitly when outside a git directory.)_ |
	| `past`, `summary` | Outlines the last 17 commits made before `HEAD` with a commit graph. |
	| `future` | Outlines the next 17 commits made after `HEAD` with a commit graph. |
	| `rw` | `checkout` 1 commit backward, alias for `checkout HEAD~1` |
	| `ff` | `checkout` 1 commit forward toward `master` |
	| `list-files` | List all tracked filenames in repo, ideally for use with `xargs`. |
	| `edit-tree [query]` | Interactive tracked plaintext file tree, opens file with `$EDITOR` in new window if `X` is running. |
	| `flatten` | Automatically melds `--fixup/squash` commits out of existence starting from the root commit. |
	| `recommit` | Stages changes to worktree and `commit --amend`s them as part of the last commit. |
	| `checkin` | Commit all changes immediately with a generic timestamp and hostname commit message. |
	| `shove` | Runs `checkin` and pushes immediately. |
	| `sync` | Runs `git meta pull` and then recurses through `~/Git` and runs `git pull` on every existing `git` repo found. |
	| `vacuum` | Runs `git meta gc` and then recurses through `~/Git` and runs `git gc` on every existing `git` repo found. |

## `nano`
> **NOTE**<br/>
> _`nano` keybind macros make use of inline non-printable control characters, you must use `nano` or `cat -v` to view [`~/.nanorc`](.nanorc) correctly._

* `nano` is an alias for [`nano-overlay`](Scripts/nano_overlay.sh) which mangles config files and offers the following extended options:

	| opt | function |
	| -- | -- |
	| `-e, --ctags <tag> <#>` | Jumps into file containing `ctags` definition matching `<tag>`. <br/>_Optional `<#>` selects from multiple matches, `all` will open all of them._ |
	| `-c, --ctags-dict <file1>...` | Enable project-wide autocomplete by appending condensed dictionary of all `ctags` keywords to all files. <br/>_Dictionary will be removed upon exiting._ |
	| `-f, --encrypt <file>` | Open AES encrypted text file with a plaintext password. <br/>_File will be created if it doesn't exist._ |
	| `-j, --rsa <file>` | Open AES encrypted text file with generic RSA keypair in PEM format. <br/>_File will be created if it doesn't exist._ |
	| `-s, --ssh-sign <file>` | Open AES encrypted text file with a nonce value signed with SSH private key. <br/>_File will be created if it doesn't exist._ |
	| `-i, --identity <key>` | Use an OpenSSL compatible keypair to encrypt/decrypt. <br/>_Can be a private key or a public key with private half stored in `ssh-agent`_ |

* Once inside the actual `nano`, the following keybind macros are available:

	| key | function |
	| -- | -- |
	| `M-0` | Execute current line as shell command and pipe contents of buffer as stdin.<br/>_Destructively replaces entire contents of buffer, useful for formatting._ |
	| `M-1` | Execute current line as shell command and paste output in current buffer.<br/>_Commands within inline comments are accepted._ |
	| `M-2` | Select token underneath cursor and jump into its `ctags` definition(s) within the same shell.<br/>_Requires valid `tags` file in current or a parent directory._ |
	| `M-4` | Select token underneath cursor and jump into its `ctags` definition(s) in a new terminal window.<br/>_Requires valid `tags` file in current or a parent directory._ |

## `notify-send`
This particular [`notify-send`](.local/lib/notify-send) implements only `-t` for expiration time in seconds,
because it doesn't tie into any `dbus`-based notification daemon implementing the [Desktop Notifications spec][notify].

[notify]: https://specifications.freedesktop.org/notification-spec/latest/
	"freedesktop.org Desktop Notifications spec"

Instead, it's just a shell script that writes to a named pipe that gets picked up by [`xwin-statusd`](Scripts/wm_status.sh) as a simple way to implement OSD text and single-line notifications.

Unlike other implementations, you can pass notifications/OSD text as an argument or via stdin without using `xargs`.

## `sc` (spreadsheet calculator)
`sc` supports macros to some degree, but its macro implementation is [difficult to understand][sc_macros] and there aren't many examples of it being used successfully anywhere that I've managed to find.

[sc_macros]: https://github.com/n-t-roff/sc/blob/master/SC.MACROS "I'm not even sure this was implemented as written."

Instead, the shell function `sc()` offers an easier to understand macro system for statically mangling `.sc` spreadsheet files at runtime.
* `sc` will automatically run any executable sharing the same initial name as the `.sc` file.
	* _eg. `sheet1.sc` will run `sheet1.sc.1`, `sheet1.scx`, etc. if they exist in the same directory and are executable at runtime._
* You can write an arbitrarily complex pre-run macro script in any language, so long as it's made aware of its own filename at runtime.
	* _Because the `sc` file format is plaintext, you can generate `sc` syntax with just a shell script._

### `sc` pre-run macro example scripts
1. A macro script for an inventory spreadsheet that color-codes cells when specific strings are found.

	```shell
	#!/usr/bin/env sh
	# apply colors to specific strings in column B

	file="${0%.*}" # derive .sc file name from name of this script

	# remove all instances of color from the file in place
	{ rm "$file"; egrep -v '^color' > "$file"; } < "$file"

	cat <<- EOF >> "$file" # set some non-default colors
		color 3 = @black;@red
		color 4 = @black;@yellow
		color 5 = @black;@green
	EOF
	# select only string cells from column B, apply colors based on string contents
	# sc format: leftstring B2 = "example string"
	egrep '^((left|right)string|label)' < "$file" | while read -r cmd cell _ str; do
		case "$cell" in B*)
			case "$str" in
				*broken*) echo "color $cell:$cell 3";;
				*bad*) echo "color $cell:$cell 4";;
				*working*) echo "color $cell:$cell 5";;
			esac;;
		esac
	done >> "$file"
	```

2. A macro script that extracts specific fields from a spreadsheet and mangles them into arbitrary JSON data, I use this to update my [figure collection page ](https://microsounds.github.io/notes/figures.htm) on my personal site.
	 * `sc` is very old and predates most notions of CSV or tab delimited data,
the easiest way to extract fields with spaces is use `expect` to output a colon separated table using the `T` command _"interactively"_,
write it to the default filename ending in `.cln`, and then delete it when finshed.


	```shell
	#!/usr/bin/env sh

	# generate simplified JSON data for website
	file="${0%.*}"

	expect <<- EOF > /dev/null
		spawn sc "$file"
		expect "sc 7.16" {
			send -- "T\\\\n"
		}
		expect "i> tbl" {
			send -- "\\\\n Q\\\\n"
			expect eof
		}
	EOF

	# replace empty colon delimited fields with '(null)' for consistency
	# yes this is very ugly
	cat "${file%.*}.cln" \
		| sed -e '/^::/d' -e 's/^:/(null):/g' -e 's/::/:(null):/g' \
			-e 's/::/:(null):/g' -e 's/:$/:(null)/g' \
		| tr ':' '\\\\t' | cut -f1-5 | tail -n +5 | while read -r status id key desc; do
			case "$desc" in
				knockoff*|counterfeit*|fake*) id="x$id";;
				*)	case "$status" in
						unopened|displayed|storage);;
						wishlist) id="w$id";;
						*) id="p$id";;
					esac;;
			esac
			year="${desc#*	}"
			desc="${desc%	$year}"
			desc="$(echo "$desc" | sed "s/'/\\\\\\\\\\\\\\\\'/g")" # escape quotes
			printf "\\\\t[ '%s', '%s', '%s (%s)' ],\\\\n" \
				"$id" "$key" "$desc" "$year"
	done > "${file%.*}.json"

	rm -f "${file%.*}.cln"
	```

[scrot]: https://raw.githubusercontent.com/microsounds/microsounds/master/dotfiles/scrot.png
[shimeji]: https://raw.githubusercontent.com/microsounds/microsounds/master/dotfiles/shimeji.png
