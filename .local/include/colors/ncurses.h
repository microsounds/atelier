#ifndef NCURSES_H
#define NCURSES_H

#include "nightdrive.h"

/*
 * high contrast overrides for ncurses applications
 * that make use of strong background colors such as blue or red
 */

/* black */
#undef COLOR0
#define COLOR0	BGCOLOR

/* red */
#undef COLOR1
#define COLOR1	#C50F1F

/* yellow */
#undef COLOR2
#define COLOR2	#13A10E

/* red */
#undef COLOR3
#define COLOR3	#C19C00

/* white */
#undef COLOR7
#define COLOR7	FGCOLOR

#endif /* NCURSES_H */
