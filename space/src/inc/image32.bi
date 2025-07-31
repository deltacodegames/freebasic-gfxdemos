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
    as integer pixrange
    as string label
    as _long_  w, h
    declare constructor        ()
    declare constructor        (w as _long_, h as _long_, label as string = "")
    declare function create    (w as _long_, h as _long_, label as string = "") as Image32
    declare function free      () as Image32
    declare function getPixel  (x as _long_, y as _long_) as ulong
    declare function getPixel  (x as double, y as double) as ulong
    declare function load      (filename as string) as Image32
    declare function readInfo  (imageBuffer as any ptr) as Image32
    declare function plotPixel (x as _long_, y as _long_, colr as ulong) as Image32
end type
