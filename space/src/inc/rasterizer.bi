' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
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
    declare function addBuffer(w as integer, h as integer, bpp as integer, pitch as integer, pixdata as any ptr = 0) as integer
    declare function getBuffer(index as integer) as Buffer2 ptr
    declare      sub clipPoly overload(vertexes() as Vector2, clipped() as Vector2, side as integer = 0)
    declare      sub clipPoly overload(vertexes() as Vector2, uvs() as Vector2, clippedVerts() as Vector2, clippedUvs() as Vector2, side as integer = 0)
    declare      sub drawFlatPoly(vertexes() as Vector2, colr as ulong)
    declare      sub drawFlatTri(a as Vector2, b as Vector2, c as Vector2, colr as ulong)
    declare      sub drawTexturedPoly(vertexes() as Vector2, uvs() as Vector2, texture as any ptr)
    declare      sub drawTexturedTri(a as Vector2, b as Vector2, c as Vector2, u as Vector2, v as Vector2, w as Vector2, texture as any ptr)
    declare      sub drawTexturedTri2(a as Vector2, b as Vector2, c as Vector2, u as Vector2, v as Vector2, w as Vector2, texture as any ptr)
    declare      sub drawTexturedTriLowQ(a as Vector2, b as Vector2, c as Vector2, u as Vector2, v as Vector2, e as Vector2, texture as any ptr, quality as integer = 0)
    declare      sub drawWireframePoly(vertexes() as Vector2, colr as ulong = &hffffff, style as ushort = &hffff)
    declare function init() as integer
    declare function setBuffer(index as integer) as integer
    declare      sub scalePut(src as Rect, dst as Rect)
    declare      sub shutdown()
end namespace
