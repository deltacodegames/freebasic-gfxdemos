' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "rasterizer.bi"
#include once "image32.bi"

#macro array_append(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
#endmacro

declare sub drawFlatTrapezoid(a as Vector2, c as Vector2, b as Vector2, d as Vector2, colr as integer)
declare sub drawTexturedHorizontalLine overload(rowStart as any ptr, x0 as integer, x1 as integer, u as Vector2, v as Vector2, image as Image32)
declare sub drawTexturedHorizontalLine overload(rowStart as any ptr, x0 as integer, x1 as integer, u as Vector3, v as Vector3, image as Image32)
declare sub drawTexturedTrapezoid overload(a as Vector2, c as Vector2, b as Vector2, d as Vector2, p as Vector2, r as Vector2, q as Vector2, s as Vector2, texture as any ptr)
declare sub drawTexturedTrapezoid overload(a as Vector2, c as Vector2, b as Vector2, d as Vector2, p as Vector3, r as Vector3, q as Vector3, s as Vector3, texture as any ptr)
namespace Rasterizer
    declare      sub clipPoly overload(vertexes() as Vector2, clipped() as Vector2, side as integer = 0)
    declare      sub drawFlatTri(a as Vector2, b as Vector2, c as Vector2, colr as ulong)
    declare      sub drawTexturedTri overload(a as Vector2, b as Vector2, c as Vector2, u as Vector2, v as Vector2, w as Vector2, texture as any ptr)
    declare      sub drawTexturedTri overload(a as Vector2, b as Vector2, c as Vector2, u as Vector3, v as Vector3, w as Vector3, texture as any ptr)
end namespace


function lerpd overload(from as double, goal as double, ratio as double = 0.5) as double
    ratio = iif(ratio < 0, 0, iif(ratio > 1, 1, ratio))
    return from + (goal - from) * ratio
end function

function Rasterizer.addBuffer(w as integer, h as integer, bpp as integer, pitch as integer, pixdata as any ptr = 0) as integer
    dim as integer ub
    if pixdata = 0 then
        pixdata = allocate(h * pitch * bpp)
    end if
    if pixdata then
        ub = ubound(buffers) + 1
        redim preserve buffers(ub)
        buffers(ub).w       = w
        buffers(ub).h       = h
        buffers(ub).bpp     = bpp
        buffers(ub).pitch   = pitch
        buffers(ub).pixdata = pixdata
        return ub
    else
        return 0
    end if
end function
function Rasterizer.init() as integer
    dim as integer index = -1
    dim as _long_ w, h, bpp, pitch
    screeninfo w, h, , bpp, pitch
    index = addBuffer(w, h, bpp, pitch, screenptr)
    if index = lbound(buffers) then
        setBuffer(index)
        return 0
    else
        return -1
    end if
end function
function Rasterizer.getBuffer(index as integer) as Buffer2 ptr
    if index >= lbound(buffers) and index <= ubound(buffers) then
        return @buffers(index)
    end if
end function
function Rasterizer.setBuffer(index as integer) as integer
    dim as Buffer2 ptr buffer
    if index >= lbound(buffers) and index <= ubound(buffers) then
        buffer = getBuffer(index)
        if buffer then
            BUFFER_W       = buffer->w
            BUFFER_H       = buffer->h
            BUFFER_BPP     = buffer->bpp
            BUFFER_PITCH   = buffer->pitch
            BUFFER_PIXDATA = buffer->pixdata
            return 0
        else
            return -2
        end if
    else
        return -1
    end if
end function
sub Rasterizer.shutdown()
    for i as integer = 0 to ubound(buffers)
        if buffers(i).pixdata then
            if buffers(i).pixdata <> screenptr then
                deallocate buffers(i).pixdata
            end if
        end if
    next i
    erase buffers
end sub
private sub Rasterizer.clipPoly overload(vertexes() as Vector2, clipped() as Vector2, side as integer = 0)
    dim as Vector2 a, b, c, newVerts(any)
    dim as integer x0 = 0, x1 = BUFFER_W-1
    dim as integer y0 = 0, y1 = BUFFER_H-1
    select case side
    case 0
        for i as integer = 0 to ubound(vertexes)
            a = vertexes(i)
            b = iif(i < ubound(vertexes), vertexes(i+1), vertexes(0))
            if a.x <= x1 then
                array_append(newVerts, a)
                if b.x > x1 then
                    c = a + (b-a) * (x1-a.x)/(b.x-a.x)
                    array_append(newVerts, c)
                end if
            elseif b.x <= x1 then
                c = b + (a-b) * (x1-b.x)/(a.x-b.x)
                array_append(newVerts, c)
            end if
        next i
    case 1
        for i as integer = 0 to ubound(vertexes)
            a = vertexes(i)
            b = iif(i < ubound(vertexes), vertexes(i+1), vertexes(0))
            if a.y >= y0 then
                array_append(newVerts, a)
                if b.y < y0 then
                    c = a + (b-a) * (a.y-y0)/(a.y-b.y)
                    array_append(newVerts, c)
                end if
            elseif b.y >= y0 then
                c = b + (a-b) * (b.y-y0)/(b.y-a.y)
                array_append(newVerts, c)
            end if
        next i
    case 2
        for i as integer = 0 to ubound(vertexes)
            a = vertexes(i)
            b = iif(i < ubound(vertexes), vertexes(i+1), vertexes(0))
            if a.x >= x0 then
                array_append(newVerts, a)
                if b.x < x0 then
                    c = a + (b-a) * (a.x-y0)/(a.x-b.x)
                    array_append(newVerts, c)
                end if
            elseif b.x >= x0 then
                c = b + (a-b) * (b.x-x0)/(b.x-a.x)
                array_append(newVerts, c)
            end if
        next i
    case 3
        for i as integer = 0 to ubound(vertexes)
            a = vertexes(i)
            b = iif(i < ubound(vertexes), vertexes(i+1), vertexes(0))
            if a.y <= y1 then
                array_append(clipped, a)
                if b.y > y1 then
                    c = a + (b-a) * (y1-a.y)/(b.y-a.y)
                    array_append(clipped, c)
                end if
            elseif b.y <= y1 then
                c = b + (a-b) * (y1-b.y)/(a.y-b.y)
                array_append(clipped, c)
            end if
        next i
    end select
    if side < 3 then
        clipPoly newVerts(), clipped(), side + 1
    end if
end sub
sub Rasterizer.drawFlatPoly(vertexes() as Vector2, colr as ulong)
    dim as Vector2 a, b, c, clipped(any)
    clipPoly vertexes(), clipped()
    if ubound(clipped) >= 2 then
        for i as integer = 1 to ubound(clipped)-1
            a = clipped(0)
            b = clipped(i)
            c = clipped(i+1)
            drawFlatTri(a, b, c, colr)
        next i
    end if
end sub
private sub Rasterizer.drawFlatTri(a as Vector2, b as Vector2, c as Vector2, colr as ulong)
    dim as Vector2 d
    if a.y > b.y then swap a, b
    if a.y > c.y then swap a, c
    if b.y > c.y then swap b, c
    a = int(a)
    b = int(b)
    c = int(c)
    if a.y < b.y and b.y < c.y then
        d.x = a.x + (b.y - a.y) * (c.x - a.x) / (c.y - a.y)
        d.y = b.y
        drawFlatTrapezoid a, a, b, d, colr
        drawFlatTrapezoid b, d, c, c, colr
    elseif a.y < b.y and b.y = c.y then
        drawFlatTrapezoid a, a, b, c, colr
    elseif a.y = b.y and b.y < c.y then
        drawFlatTrapezoid a, b, c, c, colr
    else
        if a.x < b.x then swap a, b
        if a.x < c.x then swap a, c
        if b.x < c.x then swap b, c
        line(a.x, a.y)-(b.x, b.y), colr
    end if
end sub
sub Rasterizer.drawTexturedPoly(vertexes() as Vector2, uvs() as Vector2, texture as any ptr)
    dim as Vector2 a, b, c, u, v, w
    for i as integer = 1 to ubound(vertexes)-1
        a = vertexes(0)
        b = vertexes(i)
        c = vertexes(i+1)
        u = uvs(0)
        v = uvs(i)
        w = uvs(i+1)
        drawTexturedTri a, b, c, u, v, w, texture
    next i
end sub
sub Rasterizer.drawTexturedPoly(vertexes() as Vector2, uvs() as Vector3, texture as any ptr)
    dim as Vector2 a, b, c
    dim as Vector3 u, v, w
    for i as integer = 1 to ubound(vertexes)-1
        a = vertexes(0)
        b = vertexes(i)
        c = vertexes(i+1)
        u = uvs(0)
        v = uvs(i)
        w = uvs(i+1)
        drawTexturedTri a, b, c, u, v, w, texture
    next i
end sub
private sub Rasterizer.drawTexturedTri(a as Vector2, b as Vector2, c as Vector2, u as Vector2, v as Vector2, w as Vector2, texture as any ptr)
    dim as Vector2 d, x
    if a.y > b.y then swap a, b: swap u, v
    if a.y > c.y then swap a, c: swap u, w
    if b.y > c.y then swap b, c: swap v, w
    a = int(a)
    b = int(b)
    c = int(c)
    if a.y < b.y and b.y < c.y then
        d = lerp(a, c, (b.y - a.y) / (c.y - a.y))
        x = lerp(u, w, (b.y - a.y) / (c.y - a.y))
        drawTexturedTrapezoid a, a, b, d, u, u, v, x, texture
        drawTexturedTrapezoid b, d, c, c, v, x, w, w, texture
    elseif a.y < b.y and b.y = c.y then
        drawTexturedTrapezoid a, a, b, c, u, u, v, w, texture
    elseif a.y = b.y and b.y < c.y then
        drawTexturedTrapezoid a, b, c, c, u, v, w, w, texture
    else
        if a.x < b.x then swap a, b
        if a.x < c.x then swap a, c
        if b.x < c.x then swap b, c
        line(a.x, a.y)-(b.x, b.y), &hff00ff
    end if
end sub
private sub Rasterizer.drawTexturedTri(a as Vector2, b as Vector2, c as Vector2, u as Vector3, v as Vector3, w as Vector3, texture as any ptr)
    dim as Vector2 d
    dim as Vector3 x
    if a.y > b.y then swap a, b: swap u, v
    if a.y > c.y then swap a, c: swap u, w
    if b.y > c.y then swap b, c: swap v, w
    a = int(a)
    b = int(b)
    c = int(c)
    u = type(u.x, u.y, 1) / u.z
    v = type(v.x, v.y, 1) / v.z
    w = type(w.x, w.y, 1) / w.z
    if a.y < b.y and b.y < c.y then
        d = lerp(a, c, (b.y - a.y) / (c.y - a.y))
        x = lerp(u, w, (b.y - a.y) / (c.y - a.y))
        drawTexturedTrapezoid a, a, b, d, u, u, v, x, texture
        drawTexturedTrapezoid b, d, c, c, v, x, w, w, texture
    elseif a.y < b.y and b.y = c.y then
        drawTexturedTrapezoid a, a, b, c, u, u, v, w, texture
    elseif a.y = b.y and b.y < c.y then
        drawTexturedTrapezoid a, b, c, c, u, v, w, w, texture
    else
        if a.x < b.x then swap a, b
        if a.x < c.x then swap a, c
        if b.x < c.x then swap b, c
        line(a.x, a.y)-(b.x, b.y), &hff00ff
    end if
end sub
sub Rasterizer.drawWireframePoly(vertexes() as Vector2, colr as ulong = &hffffff, style as ushort = &hffff)
    dim as Vector2 a, b, clipped(any)
    clipPoly vertexes(), clipped()
    if ubound(clipped) >= 2 then
        for i as integer = 0 to ubound(clipped)
            a = clipped(i)
            b = iif(i < ubound(clipped), clipped(i + 1), clipped(0))
            line (a.x, a.y)-(b.x, b.y), colr, , style
        next i
        for i as integer = 0 to ubound(clipped)
            a = clipped(i)
            line (a.x-2, a.y-2)-step(3, 3), &h00ff00, b, style
        next i
    end if
end sub
'==============================================================================
'= PRIVATE SUBS
'==============================================================================
private sub drawFlatTrapezoid(a as Vector2, c as Vector2, b as Vector2, d as Vector2, colr as integer)
    dim as double ab, cd
    dim as double abx, cdx
    dim as integer y0, y1
    ab = a.x
    cd = c.x
    abx = (b.x - a.x) / (b.y - a.y)
    cdx = (d.x - c.x) / (d.y - c.y)
    y0 = a.y
    y1 = y0 + (b.y - a.y)
    screenlock
    for i as integer = y0 to y1
        line (int(ab), i)-(int(cd), i), colr
        ab += abx
        cd += cdx
    next i
    screenunlock
end sub
private sub drawTexturedHorizontalLine(rowStart as any ptr, x0 as integer, x1 as integer, u as Vector2, v as Vector2, image as Image32)
    using Rasterizer
    dim as Vector2 uv, duv
    dim as integer cx0, cx1, w
    dim as ulong ptr pixel
    dim as double ratio

    if x0 > x1 then swap x0, x1: swap u, v

    w     = x1 - x0 + 1
    cx0   = iif(x0 >= 0, x0, 0)
    cx1   = iif(x1 <= BUFFER_W-1, x1, BUFFER_W-1)
    ratio = (0.5 + cx0 - x0) / w
    uv    = lerp(u, v, ratio)
    duv   = (v - u) / w
    
    pixel = rowStart
    pixel += cast(_long_, cx0)
    for x as integer = cx0 to cx1
        *pixel = image.getPixel(uv.x, uv.y)
        pixel += 1
        uv += duv
    next x
end sub
private sub drawTexturedHorizontalLine(rowStart as any ptr, x0 as integer, x1 as integer, u as Vector3, v as Vector3, image as Image32)
    using Rasterizer
    dim as Vector3 uv, duv
    dim as integer cx0, cx1, w
    dim as ulong ptr pixel
    dim as double ratio

    if x0 > x1 then swap x0, x1: swap u, v

    w     = x1 - x0 + 1
    cx0   = iif(x0 >= 0, x0, 0)
    cx1   = iif(x1 <= BUFFER_W-1, x1, BUFFER_W-1)
    ratio = (0.5 + cx0 - x0) / w
    uv    = lerp(u, v, ratio)
    duv   = (v - u) / w
    
    pixel = rowStart
    pixel += cast(_long_, cx0)
    for x as integer = cx0 to cx1
        *pixel = image.getPixel(uv.x / uv.z, uv.y / uv.z)
        pixel += 1
        uv += duv
    next x
end sub
private sub drawTexturedTrapezoid(a as Vector2, c as Vector2, b as Vector2, d as Vector2, p as Vector2, r as Vector2, q as Vector2, s as Vector2, texture as any ptr)
    using Rasterizer
    dim as Image32 image
    dim as Vector2 uv0, uv1, duv0, duv1
    dim as any ptr buffer, rowStart
    dim as integer ctop, cbtm, h, top, btm
    dim as double  perc, skip, dx0, dx1, x0, x1
    image.readInfo(texture)
    buffer = screenptr
    if image.pixdata <> 0 and buffer <> 0 then
        if a.x > c.x then swap a, c: swap p, r
        if b.x > d.x then swap b, d: swap q, s
        top = a.y
        btm = b.y
        h   = btm - top + 1
        ctop = iif(top >= 0, top, 0)
        cbtm = iif(btm <= BUFFER_H-1, btm, BUFFER_H-1)
        skip = ctop - top
        perc = (0.5 + skip) / h
        x0 = lerpd(a.x, b.x, perc)
        x1 = lerpd(c.x, d.x, perc)
        dx0 = (b.x - a.x) / h
        dx1 = (d.x - c.x) / h
        uv0 = lerp(p, q, perc)
        uv1 = lerp(r, s, perc)
        duv0 = (q - p) / h
        duv1 = (s - r) / h
        rowStart = buffer + ctop*BUFFER_PITCH
        screenlock
        for y as integer = ctop to cbtm
            drawTexturedHorizontalLine rowStart, int(x0), int(x1), uv0, uv1, image
            x0 += dx0
            x1 += dx1
            uv0 += duv0
            uv1 += duv1
            rowStart += BUFFER_PITCH
        next y
        screenunlock
    end if
end sub
private sub drawTexturedTrapezoid(a as Vector2, c as Vector2, b as Vector2, d as Vector2, p as Vector3, r as Vector3, q as Vector3, s as Vector3, texture as any ptr)
    using Rasterizer
    dim as Image32 image
    dim as Vector3 uv0, uv1, duv0, duv1
    dim as any ptr buffer, rowStart
    dim as integer ctop, cbtm, h, top, btm
    dim as double  perc, skip, dx0, dx1, x0, x1
    image.readInfo(texture)
    buffer = screenptr
    if image.pixdata <> 0 and buffer <> 0 then
        if a.x > c.x then swap a, c: swap p, r
        if b.x > d.x then swap b, d: swap q, s
        top = a.y
        btm = b.y
        h   = btm - top + 1
        ctop = iif(top >= 0, top, 0)
        cbtm = iif(btm <= BUFFER_H-1, btm, BUFFER_H-1)
        skip = ctop - top
        perc = (0.5 + skip) / h
        x0 = lerpd(a.x, b.x, perc)
        x1 = lerpd(c.x, d.x, perc)
        dx0 = (b.x - a.x) / h
        dx1 = (d.x - c.x) / h
        uv0 = lerp(p, q, perc)
        uv1 = lerp(r, s, perc)
        duv0 = (q - p) / h
        duv1 = (s - r) / h
        rowStart = buffer + ctop*BUFFER_PITCH
        screenlock
        for y as integer = ctop to cbtm
            drawTexturedHorizontalLine rowStart, int(x0), int(x1), uv0, uv1, image
            x0 += dx0
            x1 += dx1
            uv0 += duv0
            uv1 += duv1
            rowStart += BUFFER_PITCH
        next y
        screenunlock
    end if
end sub
