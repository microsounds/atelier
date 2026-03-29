#ifndef THEME_H
#define THEME_H

/*
 * Notes on HiDPI and readability
 *
 * fontconfig font sizes are defined in 'pixelsize' by default
 * Readability optimized for low density displays up to 1080p @ 18" or greater
 *
 * OPTIONAL: define HIDPI_MODE on systems with high density displays,
 *           eg. 4K displays below 24", 1080p @ 13" or smaller.
 * Control display density setting via 'Xft.dpi' in ~/.xresources
 * You must recompile dwm/dmenu for changes to take effect.
 * Restart X to apply to all other applications respecting ~/.xresources
 */
#undef HIDPI_MODE

/* utilities and fontconfig boilerplate */
#define _xstr(s) #s
#define str(s) _xstr(s)
#define font(name, px) name:pixelsize=px

/* font size in pixelsize */
#define FN_TERM        Go Mono
#define FN_TERM_JP     VL Gothic
#define FN_TERM_SIZE   13

#define FN_TEXT        Liberation Sans
#define FN_TEXT_SIZE   9

#define FN_HEADER      Liberation Serif
#define FN_HEADER_JP   Dejima
#define FN_HEADER_SIZE 16

#define FN_EMOJI       DejaVu Sans
#define FN_EMOJI_SIZE  16

#ifdef HIDPI_MODE
/* 	font size in relative size */
	#define font(name, px) name:size=px
	#define FN_TERM_SIZE	10
	#define FN_TEXT_SIZE	9
	#define FN_HEADER_SIZE	12
	#define FN_EMOJI_SIZE	12
#endif

/*
 * Notes on theming and display issues
 *
 * Fallback glyphs and FN_EMOJI (future)
 * Emoji glyphs are currently provided by fallback font DejaVu Sans in
 * all applications, future changes to Debian might necessitate introducing a
 * subset of DejaVu Sans or another font with just emoji glyphs to
 * selectively override FN_{TERM,TEXT,HEADER}, generated during post-install.

 * Changes requires for HiDPI
 * fontconfig boilerplate must be changed to relative name:size=px
 * FN_TERM changes to size 10, FN_HEADER changes to size 12
 * xwin-widgets will have to apply multiplers based on reported DPI
 *
 * Major problems with HiDPI
 * HiDPI is global, you cannot set DPI per monitor, only per X screen.
 * 	- Multi-monitor setups with widely different DPI densities are an exercise in pain.
 * Xft.dpi value in ~/.xresources is respected mostly everywhere
 *  - X pointer has an absolute pixelsize and is unusable without overrides
 *  - certain emoji glyphs in dwm title bar become tiny and unusable at high DPIs
 *  - dwm border widths are defined in pixels and are nearly invisible at 200+ DPI
 */

#endif /* THEME_H */
