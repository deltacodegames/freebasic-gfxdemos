' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#ifdef __FB_64BIT__
    #define _long_ longint
    #define _ulong_ ulongint
#else
    #define _long_ long
    #define _ulong_ ulong
#endif

type ScreenModeType
    as _long_  bpp
    as _long_  depth
    as string  driver
    as _long_  flags
    as _long_  pages
    as _long_  pitch
    as _long_  rate
    as double  ratioh
    as double  ratiow
    as double  viewbtm
    as double  viewlft
    as double  viewrgt
    as double  viewtop
    as _long_  w, h
    declare function applySettings() as integer
    declare function applyView() as ScreenModeType
    declare function readSettings() as ScreenModeType
    declare function resetView() as ScreenModeType
    declare function setView(lft as double, top as double, rgt as double, btm as double) as ScreenModeType
end type
