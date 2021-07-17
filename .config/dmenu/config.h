/* ~/.config/dmenu/config.h: dmenu user configuration */

#include <theme.h>
#include <colors/nightdrive.h>

/* ux color theme */
static const char *colors[SchemeLast][2] = {
	/*               fg            bg       */
	[SchemeNorm] = { str(FGCOLOR), str(BGCOLOR) },
	[SchemeSel]  = { str(FGCOLOR), str(FGLIGHT) },
	[SchemeOut]  = { str(COLOR0),  str(COLOR6)  },   /* Ctrl+Enter multiple select */
};

/* ux appearance */
static const char *fonts[] = {
	str(font(FN_HEADER, FN_HEADER_SIZE)),         /* normal */
	str(font(FN_HEADER_JP, FN_HEADER_SIZE))       /* fallback japanese */
};

/* options */
static int topbar = 1;
static unsigned int lines = 0;
static const char *prompt = NULL;
static const char worddelimiters[] = " ";
