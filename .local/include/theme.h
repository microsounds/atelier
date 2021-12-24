#ifndef THEME_H
#define THEME_H

/*
 * Notes on theming and display issues
 *
 * Fallback glyphs and FN_EMOJI (future)
 * Emoji glyphs are currently provided by fallback font DejaVu Sans in
 * all applications, future changes to Debian might necessitate introducing a
 * subset of DejaVu Sans or another font with just emoji glyphs to
 * selectively override FN_{TERM,TEXT,HEADER}, generated during post-install.

 * Future changes required for HiDPI
 * fontconfig boilerplate must be changed to relative name:size=px
 * FN_TERM changes to size 10, FN_HEADER changes to size 12
 * xwin-widgets will have to apply multiplers based on reported DPI
 *
 * Major problems with HiDPI
 * Xft.dpi value in ~/.xresources is respected mostly everywhere
 *  - x pointer has an absolute pixelsize and is unusable without overrides
 *  - certain emoji glyphs in dwm are absolutely tiny and unusable
 *  - border widths in dwm are defined in pixel widths and also practically invisible
 *  - HiDPI support is lacking in many unexpected places, not going to bother.
 */

/* utilities and fontconfig boilerplate */
#define _xstr(s) #s
#define str(s) _xstr(s)
#define font(name, px) name:pixelsize=px

/* font size in pixel height */
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

#endif /* THEME_H */
