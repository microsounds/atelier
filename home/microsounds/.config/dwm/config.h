#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx = 1;	/* window border width */
static const unsigned int snap = 16;	/* snap pixel */
static const int showbar = 1;			/* 0 means no bar */
static const int topbar = 1;			/* 0 means bottom bar */
static const char *fonts[] = {
	"Liberation Serif:size=12",
	"Unifont:size=12"	/* japanese serifs */
};
static const char dmenufont[] = "Liberation Serif:size=12";
static const char col_gray1[] = "#272727";
static const char col_gray2[] = "#646464";
static const char col_gray3[] = "#FFFFFF";
static const char col_gray4[] = "#FFFFFF"; /* fg text */
static const char col_cyan[]  = "#B24A7A"; /* CDE salmon pink~ */
static const char *colors[][3]= {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan },
};

/* tagging */
static const char *tags[] = { "あ", "か", "さ", "た", "な" }; /* はまやらわ */

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      instance    title       tags mask     isfloating   monitor */
	{ "Gimp",     NULL,       NULL,       0,            1,           -1 },
	{ "Firefox",  NULL,       NULL,       1 << 8,       0,           -1 },
	{ "XLoad",    NULL,       NULL,       0,            1,           -1 },
	{ "XClock",   NULL,       NULL,       0,            1,           -1 },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* ignore column limitations in terminals */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "~tile",      tile },    /* tiling */
	{ "~float",      NULL },    /* floating */
	{ "[M]",      monocle },
};

/* built-in commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[]  = { "urxvt", NULL };

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* volume functions */
static const char *vol_up[] = { "amixer", "-q", "sset", "Master", "2%+", NULL };
static const char *vol_dn[] = { "amixer", "-q", "sset", "Master", "2%-", NULL };
static const char *vol_mute[] = { "amixer", "-q", "-D", "pulse", "sset", "Master", "toggle", NULL };

/* modifier keys */
#define SHIFT ShiftMask
#define CTRL ControlMask
#define META Mod4Mask
#define ALT Mod1Mask

#define TAGKEYS(KEY, TAG) \
	{ META,					KEY,	view,           { .ui = 1 << TAG } }, \
	{ CTRL | META,			KEY,	toggleview,     { .ui = 1 << TAG } }, \
	{ META | SHIFT,			KEY,	tag,            { .ui = 1 << TAG } }, \
	{ CTRL | META | SHIFT,	KEY,	toggletag,      { .ui = 1 << TAG } },

static Key keys[] = {
	/* modifiers	+ key		action		args */
	{ META,			XK_r,		spawn,			{ .v = dmenucmd } },	/* dmenu */
	{ META,			XK_Return,	spawn,			{ .v = termcmd } },		/* termi */
	{ ALT,			XK_F4,		killclient,		{0} },					/* ALT+F4 */
	{ CTRL | SHIFT, XK_q,		quit,			{0} },					/* exit dwm */
	{ META,			XK_b,		togglebar,		{0} },					/* hide bar */
	{ META,			XK_Tab,		view,			{0} },					/* cycle tags */
	{ ALT,			XK_Tab,		focusstack,		{ .i = +1 } },			/* cycle forward */
	{ ALT | SHIFT,	XK_Tab,		focusstack,		{ .i = -1 } },			/* cycle backward */
	{ META,			XK_equal,	incnmaster,		{ .i = +1 } },			/* +++ windows in master area */
	{ META,			XK_minus,	incnmaster,		{ .i = -1 } },			/* --- windows in master area */
	{ META,			XK_Left,	setmfact,		{ .f = -0.05 } },		/* +++ master area size */
	{ META,			XK_Right,	setmfact,		{ .f = +0.05 } },		/* --- master area size */
	{ ALT,			XK_Return,	zoom,			{0} },					/* promote to master area */
	{ META,			XK_t,		setlayout,		{.v = &layouts[0]} },	/* tiling mode */
	{ META,			XK_f,		setlayout,		{.v = &layouts[1]} },	/* floating mode */
	{ META,			XK_m,		setlayout,		{.v = &layouts[2]} },	/* monocle mode */
	{ META,			XK_space,	setlayout,		{0} },					/* cycle modes */
	{ META | SHIFT, XK_space,	togglefloating, {0} },					/* cycle modes for current master */
	{ META,			XK_0,		view,			{ .ui = ~0 } },			/* select all tags */
	{ META | SHIFT,	XK_0,		tag,			{ .ui = ~0 } },			/* move to all tags */
	{ META,			XK_comma,	focusmon,		{ .i = -1 } },
	{ META,			XK_period,	focusmon,		{ .i = +1 } },
	{ META | SHIFT,	XK_comma,	tagmon,			{ .i = -1 } },
	{ META | SHIFT,	XK_period,	tagmon,			{ .i = +1 } },
	{ 0,			XF86XK_AudioRaiseVolume,	spawn, { .v = vol_up } },	/* vol up */
	{ 0,			XF86XK_AudioLowerVolume,	spawn, { .v = vol_dn } },	/* vol down */
	{ 0,			XF86XK_AudioMute,			spawn, { .v = vol_mute } }, /* mute */
	TAGKEYS(XK_1, 0)
	TAGKEYS(XK_2, 1)
	TAGKEYS(XK_3, 2)
	TAGKEYS(XK_4, 3)
	TAGKEYS(XK_5, 4)
	TAGKEYS(XK_6, 5)
	TAGKEYS(XK_7, 6)
	TAGKEYS(XK_8, 7)
	TAGKEYS(XK_9, 8)
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         META,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         META,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         META,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            META,         Button1,        tag,            {0} },
	{ ClkTagBar,            META,         Button3,        toggletag,      {0} },
};

