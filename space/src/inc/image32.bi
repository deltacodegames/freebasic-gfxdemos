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

type Image32
    as any ptr buffer
    as _long_  bpp
    as _long_  pitch
    as any ptr pixdata
    as _long_  w, h
    declare function getPixel  (x as _long_, y as _long_) as ulong
    declare function getPixel  (x as double, y as double) as ulong
    declare function readInfo  (imageBuffer as any ptr) as Image32
    declare function resetInfo () as Image32
    declare function putPixel  (x as _long_, y as _long_, colr as ulong) as Image32
end type
