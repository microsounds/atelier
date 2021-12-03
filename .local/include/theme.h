#ifndef THEME_H
#define THEME_H

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

/*
 * Fallback glyphs and FN_EMOJI (future)
 * Emoji glyphs are currently provided by fallback font DejaVu Sans in
 * all applications, future changes to Debian might necessitate introducing a
 * subset of DejaVu Sans or another font with just emoji glyphs to
 * selectively override FN_{TERM,TEXT,HEADER}, generated during post-install.
 */

#endif /* THEME_H */
