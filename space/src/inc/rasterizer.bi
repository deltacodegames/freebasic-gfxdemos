' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "vector3.bi"
#include once "vector2.bi"

#ifdef __FB_64BIT__
    #define _long_ longint
    #define _ulong_ ulongint
#else
    #define _long_ long
    #define _ulong_ ulong
#endif

namespace Rasterizer
    type Buffer2
        as integer w
        as integer h
        as integer bpp
        as integer pitch
        as any ptr pixdata
    end type
    type Rect
        as integer a, b, x, y
    end type
    dim as Buffer2 buffers(any)
    dim as integer BUFFER_W, BUFFER_H, BUFFER_BPP, BUFFER_PITCH
    dim as any ptr BUFFER_PIXDATA
    dim as boolean preClipping = false
    declare function addBuffer           (w as integer, h as integer, bpp as integer, pitch as integer, pixdata as any ptr = 0) as integer
    declare function getBuffer           (index as integer) as Buffer2 ptr
    declare      sub drawFlatPoly        (vertexes() as Vector2, colr as ulong)
    declare      sub drawTexturedPoly    overload (vertexes() as Vector2, uvs() as Vector2, texture as any ptr)
    declare      sub drawTexturedPoly    overload (vertexes() as Vector2, uvs() as Vector3, texture as any ptr)
    declare      sub drawWireframePoly   (vertexes() as Vector2, colr as ulong = &hffffff, style as ushort = &hffff)
    declare function init                () as integer
    declare function setBuffer           (index as integer) as integer
    declare      sub setPreClipping      (doPreClipping as boolean)
    declare      sub shutdown            ()
    declare      sub togglePreClipping   ()
    'declare      sub scalePut            (src as Rect, dst as Rect)
end namespace
