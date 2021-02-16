/* ~/.config/dwm/config.h: dwm/dmenu user configuration */

/* utilities */
#define _xstr(s) #s
#define str(s) _xstr(s)
#define font(name, px) str(name:pixelsize=px)

/* ux color theme */
#include <colors/nightdrive.h>
static const char col_gray1[] = str(BGCOLOR);
static const char col_gray2[] = str(BGLIGHT);
static const char col_gray3[] = str(FGCOLOR);
static const char col_gray4[] = str(FGCOLOR); /* foreground text */
static const char col_cyan[]  = str(FGLIGHT);
static const char *colors[][3]= {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan },
};

/* ux appearance */
static const unsigned int borderpx = 1; /* window border width */
static const unsigned int snap = 16;    /* snap to edge distance */
static const int showbar = 1;
static const int topbar = 1;
static const char *fonts[] = {
	font(Liberation Serif, 16),         /* normal */
	font(Dejima, 16)                    /* fallback japanese */
};
static const char dmenufont[] = font(Liberation Serif, 16);

/* layouts */
static const float mfact = 0.55;        /* master area size */
static const int nmaster = 1;           /* windows in master area */
static const int resizehints = 0;       /* ignore sizing hints */
static const char *tags[] = {
	"あ", "か", "さ", "た", "な",
/* 	"は", "ま", "や", "ら", "わ" */
};
static const Layout layouts[] = {
	/* symbol	arrange function */
	{ "堅い",	tile },
	{ "中心",	monocle },
	{ "浮く",	NULL },
};
static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class           instance    title       tags mask     isfloating   monitor */
	{ "XLoad",         NULL,       NULL,       1,            1,           -1 },
	{ "XClock",        NULL,       NULL,       1,            1,           -1 },
};

/* built-in commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = {
	"dmenu_run",
	"-m", dmenumon,
	"-fn", dmenufont,
	"-nb", col_gray1,
	"-nf", col_gray3,
	"-sb", col_cyan,
	"-sf", col_gray4,
	NULL
};

/* key definitions */
#define CTRL ControlMask
#define ALT Mod1Mask
#define SUPER Mod4Mask
#define SHIFT ShiftMask

/* primary modkey */
#define MODKEY SUPER

/* command macros */
#define TERM "urxvtc"
#define SHCMD(cmd) {.v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }
/*	 modifier                       key       function        argument */
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|CTRL,                  KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|SHIFT,                 KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|CTRL|SHIFT,            KEY,      toggletag,      {.ui = 1 << TAG} },

static Key keys[] = {
/* basic */
	{ CTRL|SHIFT,                   XK_q,      quit,           {0} },
	{ MODKEY|SHIFT,                 XK_q,      quit,           {0} },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_p,      spawn,          {.v = dmenucmd } },
/* kill window */
	{ ALT,                          XK_F4,     killclient,     {0} },
	{ MODKEY,                       XK_q,      killclient,     {0} },
	{ MODKEY|SHIFT,                 XK_c,      killclient,     {0} },
/* switch focus */
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ ALT,                          XK_Tab,    focusstack,     {.i = +1 } },
	{ ALT|SHIFT,                    XK_Tab,    focusstack,     {.i = -1 } },
/* master area */
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY|SHIFT,                 XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
/* layout modes */
	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY|SHIFT,                 XK_space,  togglefloating, {0} },
/* change window tags */
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|SHIFT,                 XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|SHIFT,                 XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|SHIFT,                 XK_period, tagmon,         {.i = +1 } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          SHCMD(TERM) },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
