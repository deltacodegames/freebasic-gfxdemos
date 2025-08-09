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
declare sub drawTexturedTrapezoid(a as Vector2, c as Vector2, b as Vector2, d as Vector2, p as Vector2, r as Vector2, q as Vector2, s as Vector2, texture as any ptr, colr as ulong)
declare sub drawTexturedTrapezoid2(a as Vector2, c as Vector2, b as Vector2, d as Vector2, p as Vector2, r as Vector2, q as Vector2, s as Vector2, texture as any ptr, colr as ulong)

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
sub Rasterizer.clipPoly overload(vertexes() as Vector2, clipped() as Vector2, side as integer = 0)
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
sub Rasterizer.clipPoly overload(vertexes() as Vector2, uvs() as Vector2, clippedVerts() as Vector2, clippedUvs() as Vector2, side as integer = 0)
    dim as Vector2 a, b, c, newVerts(any)
    dim as Vector2 u, v, w, newUvs(any)
    dim as integer x0 = 0, x1 = BUFFER_W-1
    dim as integer y0 = 0, y1 = BUFFER_H-1
    select case side
    case 0
        for i as integer = 0 to ubound(vertexes)
            a = vertexes(i)
            b = iif(i < ubound(vertexes), vertexes(i+1), vertexes(0))
            u = uvs(i)
            v = iif(i < ubound(uvs), uvs(i+1), uvs(0))
            if a.x <= x1 then
                array_append(newVerts, a)
                array_append(newUvs  , u)
                if b.x > x1 then
                    c = a + (b-a) * (x1-a.x)/(b.x-a.x)
                    w = u + (v-u) * (x1-a.x)/(b.x-a.x)
                    array_append(newVerts, c)
                    array_append(newUvs  , w)
                end if
            elseif b.x <= x1 then
                c = b + (a-b) * (x1-b.x)/(a.x-b.x)
                w = v + (u-v) * (x1-b.x)/(a.x-b.x)
                array_append(newVerts, c)
                array_append(newUvs  , w)
            end if
        next i
    case 1
        for i as integer = 0 to ubound(vertexes)
            a = vertexes(i)
            b = iif(i < ubound(vertexes), vertexes(i+1), vertexes(0))
            u = uvs(i)
            v = iif(i < ubound(uvs), uvs(i+1), uvs(0))
            if a.y >= y0 then
                array_append(newVerts, a)
                array_append(newUvs  , u)
                if b.y < y0 then
                    c = a + (b-a) * (a.y-y0)/(a.y-b.y)
                    w = u + (v-u) * (a.y-y0)/(a.y-b.y)
                    array_append(newVerts, c)
                    array_append(newUvs  , w)
                end if
            elseif b.y >= y0 then
                c = b + (a-b) * (b.y-y0)/(b.y-a.y)
                w = v + (u-v) * (b.y-y0)/(b.y-a.y)
                array_append(newVerts, c)
                array_append(newUvs  , w)
            end if
        next i
    case 2
        for i as integer = 0 to ubound(vertexes)
            a = vertexes(i)
            b = iif(i < ubound(vertexes), vertexes(i+1), vertexes(0))
            u = uvs(i)
            v = iif(i < ubound(uvs), uvs(i+1), uvs(0))
            if a.x >= x0 then
                array_append(newVerts, a)
                array_append(newUvs  , u)
                if b.x < x0 then
                    c = a + (b-a) * (a.x-y0)/(a.x-b.x)
                    w = u + (v-u) * (a.x-y0)/(a.x-b.x)
                    array_append(newVerts, c)
                    array_append(newUvs  , w)
                end if
            elseif b.x >= x0 then
                c = b + (a-b) * (b.x-x0)/(b.x-a.x)
                w = v + (u-v) * (b.x-x0)/(b.x-a.x)
                array_append(newVerts, c)
                array_append(newUvs  , w)
            end if
        next i
    case 3
        for i as integer = 0 to ubound(vertexes)
            a = vertexes(i)
            b = iif(i < ubound(vertexes), vertexes(i+1), vertexes(0))
            u = uvs(i)
            v = iif(i < ubound(uvs), uvs(i+1), uvs(0))
            if a.y <= y1 then
                array_append(clippedVerts, a)
                array_append(clippedUvs  , u)
                if b.y > y1 then
                    c = a + (b-a) * (y1-a.y)/(b.y-a.y)
                    w = u + (v-u) * (y1-a.y)/(b.y-a.y)
                    array_append(clippedVerts, c)
                    array_append(clippedUvs  , w)
                end if
            elseif b.y <= y1 then
                c = b + (a-b) * (y1-b.y)/(a.y-b.y)
                w = v + (u-v) * (y1-b.y)/(a.y-b.y)
                array_append(clippedVerts, c)
                array_append(clippedUvs  , w)
            end if
        next i
    end select
    if side < 3 then
        clipPoly newVerts(), newUvs(), clippedVerts(), clippedUvs(), side + 1
    end if
end sub
sub Rasterizer.drawFlatPoly(vertexes() as Vector2, colr as ulong)
    dim as Vector2 a, b, c, clipped(any)
    clipPoly vertexes(), clipped()
    for i as integer = 1 to ubound(clipped)-1
        a = clipped(0)
        b = clipped(i)
        c = clipped(i+1)
        drawFlatTri(a, b, c, colr)
    next i
end sub
sub Rasterizer.drawFlatTri(a as Vector2, b as Vector2, c as Vector2, colr as ulong)
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
    dim as Vector2 a, b, c, clippedVerts(any)
    dim as Vector2 u, v, w, clippedUvs(any)
    clipPoly vertexes(), uvs(), clippedVerts(), clippedUvs()
    for i as integer = 1 to ubound(clippedVerts)-1
        a = clippedVerts(0)
        b = clippedVerts(i)
        c = clippedVerts(i+1)
        u = clippedUvs(0)
        v = clippedUvs(i)
        w = clippedUvs(i+1)
        drawTexturedTri a, b, c, u, v, w, texture
    next i
end sub
sub Rasterizer.drawTexturedTri(a as Vector2, b as Vector2, c as Vector2, u as Vector2, v as Vector2, w as Vector2, texture as any ptr)
    dim as Vector2 d, x
    if a.y > b.y then swap a, b: swap u, v
    if a.y > c.y then swap a, c: swap u, w
    if b.y > c.y then swap b, c: swap v, w
    a = int(a)
    b = int(b)
    c = int(c)
    if a.y < b.y and b.y < c.y then
        d.x = a.x + (b.y - a.y) * (c.x - a.x) / ((c.y - a.y)+1)
        d.y = b.y
        x = u + ((w - u) / ((c.y - a.y)+1)) * (b.y - a.y)
        drawTexturedTrapezoid2 a, a, b, d, u, u, v, x, texture, &hff0000
        drawTexturedTrapezoid2 b, d, c, c, v, x, w, w, texture, &h0000ff
    elseif a.y < b.y and b.y = c.y then
        drawTexturedTrapezoid2 a, a, b, c, u, u, v, w, texture, &hffff00
    elseif a.y = b.y and b.y < c.y then
        drawTexturedTrapezoid2 a, b, c, c, u, v, w, w, texture, &h00ffff
    else
        if a.x < b.x then swap a, b
        if a.x < c.x then swap a, c
        if b.x < c.x then swap b, c
        line(a.x, a.y)-(b.x, b.y), &hff00ff
    end if
end sub
sub Rasterizer.drawTexturedTri2(a as Vector2, b as Vector2, c as Vector2, uva as Vector2, uvb as Vector2, uvc as Vector2, texture as any ptr)
    dim as _long_ bpp = BUFFER_BPP, pitch = BUFFER_PITCH
    dim as any ptr buffer, rowStart
    dim as ulong ptr pixel
    dim as Vector2 sideA, sideB, sideC
    dim as Vector2 toplft, btmrgt
    dim as Vector2 sau, sbu, scu
    dim as Vector2 bas, pro, p, n
    dim as Image32 image
    dim as integer x, y, x0, x1, y0, y1
    dim as integer xa
    dim as double sal, sbl, scl
    dim as double u, v, w
    toplft.x = iif(a.x < b.x, iif(a.x < c.x, a.x, c.x), iif(b.x < c.x, b.x, c.x))
    toplft.y = iif(a.y < b.y, iif(a.y < c.y, a.y, c.y), iif(b.y < c.y, b.y, c.y))
    btmrgt.x = iif(a.x > b.x, iif(a.x > c.x, a.x, c.x), iif(b.x > c.x, b.x, c.x))
    btmrgt.y = iif(a.y > b.y, iif(a.y > c.y, a.y, c.y), iif(b.y > c.y, b.y, c.y))
    if toplft.x >= BUFFER_W then exit sub
    if toplft.y >= BUFFER_H then exit sub
    if btmrgt.x < 0 then exit sub
    if btmrgt.y < 0 then exit sub
    if toplft.x < 0 then toplft.x = 0
    if toplft.y < 0 then toplft.y = 0
    if btmrgt.x >= BUFFER_W then btmrgt.x = BUFFER_W-1
    if btmrgt.y >= BUFFER_H then btmrgt.y = BUFFER_H-1
    bas = normalize(c-b): pro = a-b: sideA = b + bas * dot(pro, bas) - a
    bas = normalize(a-c): pro = b-c: sideB = c + bas * dot(pro, bas) - b
    bas = normalize(b-a): pro = c-a: sideC = a + bas * dot(pro, bas) - c
    sau = sideA.normalized: sbu = sideB.normalized: scu = sideC.normalized
    sal = 1/sideA.length: sbl = 1/sideB.length: scl = 1/sideC.length
    x0 = int(toplft.x): x1 = int(btmrgt.x)
    y0 = int(toplft.y): y1 = int(btmrgt.y)
    buffer = BUFFER_PIXDATA
    if buffer <> 0 then
        image.readInfo(texture)
        rowStart = buffer + y0*pitch + x0*bpp - bpp
        screenlock
        for y = y0 to y1
            xa = 0
            pixel = rowStart
            for x = x0 to x1
                pixel += 1
                if xa and (xa < x) then exit for
                p = Vector2(x, y)
                u = 1-dot(p-a, sau)*sal: if u < 0 or u > 1 then continue for
                v = 1-dot(p-b, sbu)*sbl: if v < 0 or v > 1 then continue for
                w = 1-dot(p-c, scu)*scl: if w < 0 or w > 1 then continue for
                n = uva*u + uvb*v + uvc*w
                *pixel = image.getPixel(n.x, n.y)
                xa = x + 1
            next x
            rowStart += pitch
        next
        screenunlock
    end if
end sub
sub Rasterizer.drawTexturedTriLowQ(a as Vector2, b as Vector2, c as Vector2, uva as Vector2, uvb as Vector2, uvc as Vector2, texture as any ptr, quality as integer = 0)
    dim as integer q = 2^quality
    dim as any ptr buffer
    dim as ulong colr
    dim as Vector2 sideA, sideB, sideC
    dim as Vector2 toplft, btmrgt
    dim as Vector2 sau, sbu, scu
    dim as Vector2 bas, pro, p, n
    dim as Image32 image
    dim as integer x0, x1, y0, y1
    dim as integer xa, xb, xr, yr
    dim as integer x, y
    dim as double sal, sbl, scl
    dim as double u, v, w
    buffer      = BUFFER_PIXDATA
    image.readInfo(texture)
    if buffer <> 0 and image.buffer <> 0 then
        toplft.x = iif(a.x < b.x, iif(a.x < c.x, a.x, c.x), iif(b.x < c.x, b.x, c.x))
        toplft.y = iif(a.y < b.y, iif(a.y < c.y, a.y, c.y), iif(b.y < c.y, b.y, c.y))
        btmrgt.x = iif(a.x > b.x, iif(a.x > c.x, a.x, c.x), iif(b.x > c.x, b.x, c.x))
        btmrgt.y = iif(a.y > b.y, iif(a.y > c.y, a.y, c.y), iif(b.y > c.y, b.y, c.y))
        if toplft.x >= BUFFER_W then exit sub
        if toplft.y >= BUFFER_H then exit sub
        if btmrgt.x < 0 then exit sub
        if btmrgt.y < 0 then exit sub
        if toplft.x < 0 then toplft.x = 0
        if toplft.y < 0 then toplft.y = 0
        if btmrgt.x >= BUFFER_W then btmrgt.x = BUFFER_W-1
        if btmrgt.y >= BUFFER_H then btmrgt.y = BUFFER_H-1
        bas = normalize(c-b): pro = a-b: sideA = b + bas * dot(pro, bas) - a
        bas = normalize(a-c): pro = b-c: sideB = c + bas * dot(pro, bas) - b
        bas = normalize(b-a): pro = c-a: sideC = a + bas * dot(pro, bas) - c
        sau = sideA.normalized: sbu = sideB.normalized: scu = sideC.normalized
        sal = 1/sideA.length  : sbl = 1/sideB.length  : scl = 1/sideC.length
        x0  = int(toplft.x): x1 = int(btmrgt.x)
        y0  = int(toplft.y): y1 = int(btmrgt.y)
        xr  = (x1-x0+1) and (q-1)
        yr  = (y1-y0+1) and (q-1)
        x0 -= x0 and (q-1): x1 -= x1 and (q-1)
        y0 -= y0 and (q-1): y1 -= y1 and (q-1)
        screenlock
        dim as integer i, j
        for y = y0 to y1 step q
            xa = -1
            xb = x0
            for x = x0 to x1 step q
                if (xa > -1) and (xb+q < x) then exit for
                p = Vector2(x, y)
                u = 1-dot(p-a, sau) * sal: if u < 0 or u > 1 then continue for
                v = 1-dot(p-b, sbu) * sbl: if v < 0 or v > 1 then continue for
                w = 1-dot(p-c, scu) * scl: if w < 0 or w > 1 then continue for
                n = uva*u + uvb*v + uvc*w
                colr = image.getPixel(n.x, n.y)
                line (x, y)-step(q-1, q-1), colr, bf
                if xa = -1 then xa = x
                xb = x
            next x
        next y
        screenunlock
    end if
end sub
sub Rasterizer.drawWireframePoly(vertexes() as Vector2, colr as ulong = &hffffff, style as ushort = &hffff)
    dim as Vector2 a, b, clipped(any)
    clipPoly vertexes(), clipped()
    for i as integer = 0 to ubound(clipped)
        a = clipped(i)
        b = iif(i < ubound(clipped), clipped(i + 1), clipped(0))
        line (a.x, a.y)-(b.x, b.y), colr, , style
    next i
    for i as integer = 0 to ubound(clipped)
        a = clipped(i)
        line (a.x-2, a.y-2)-step(3, 3), &h00ff00, b, style
    next i
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
private sub drawTexturedTrapezoid(a as Vector2, c as Vector2, b as Vector2, d as Vector2, p as Vector2, r as Vector2, q as Vector2, s as Vector2, texture as any ptr, colr as ulong)
    using Rasterizer
    dim as Image32 image
    dim as Vector2 uv, uvl, uvr
    dim as double ratio
    dim as integer btm, top, xl, xr, w, h, x, y
    dim as _long_ bpp = BUFFER_BPP, pitch = BUFFER_PITCH
    dim as any ptr buffer, rowStart
    dim as ulong ptr pixel
    image.readInfo(texture)
    buffer = screenptr
    if image.pixdata <> 0 and buffer <> 0 then
        if a.x > c.x then swap a, c: swap p, r
        if b.x > d.x then swap b, d: swap q, s
        if a.x >= BUFFER_W and b.x >= BUFFER_W-1 then exit sub
        if a.y >= BUFFER_H and b.y >= BUFFER_W-1 then exit sub
        if c.x < 0 and d.x < 0 then exit sub
        if c.y < 0 and d.y < 0 then exit sub
        a.x = iif(a.x < 0, 0, iif(a.x >= BUFFER_W, BUFFER_W-1, a.x))
        a.y = iif(a.y < 0, 0, iif(a.y >= BUFFER_H, BUFFER_H-1, a.y))
        b.x = iif(b.x < 0, 0, iif(b.x >= BUFFER_W, BUFFER_W-1, b.x))
        b.y = iif(b.y < 0, 0, iif(b.y >= BUFFER_H, BUFFER_H-1, b.y))
        c.x = iif(c.x < 0, 0, iif(c.x >= BUFFER_W, BUFFER_W-1, c.x))
        c.y = iif(c.y < 0, 0, iif(c.y >= BUFFER_H, BUFFER_H-1, c.y))
        d.x = iif(d.x < 0, 0, iif(d.x >= BUFFER_W, BUFFER_W-1, d.x))
        d.y = iif(d.y < 0, 0, iif(d.y >= BUFFER_H, BUFFER_H-1, d.y))
        top = a.y
        btm = b.y
        h = (btm - top) + 1
        rowStart = buffer + top*pitch
        screenlock
        for y as integer = 0 to h-1
            ratio = y / h
            uvl = lerp(p, q, ratio)
            uvr = lerp(r, s, ratio)
            xl = int(lerpd(a.x, b.x, ratio))
            xr = int(lerpd(c.x, d.x, ratio))
            w = abs(xr - xl) + 1
            pixel = rowStart + xl*bpp
            for x as integer = 0 to w-1
                ratio = x / w
                uv = lerp(uvl, uvr, ratio)
                *pixel = image.getPixel(uv.x, uv.y)
                pixel += 1
            next x
            rowStart += pitch
        next y
        screenunlock
    end if
end sub
private sub drawTexturedTrapezoid2(a as Vector2, c as Vector2, b as Vector2, d as Vector2, p as Vector2, r as Vector2, q as Vector2, s as Vector2, texture as any ptr, colr as ulong)
    using Rasterizer
    dim as Image32 image
    dim as Vector2 uv, uvx, uvl, uvr, uvi, uvj
    dim as double xl, xli, xr, xri
    dim as integer btm, top, w, h, x, y
    dim as _long_ bpp = BUFFER_BPP, pitch = BUFFER_PITCH
    dim as any ptr buffer, rowStart
    dim as ulong ptr pixel
    image.readInfo(texture)
    buffer = screenptr
    if image.pixdata <> 0 and buffer <> 0 then
        if a.x > c.x then swap a, c: swap p, r
        if b.x > d.x then swap b, d: swap q, s
        if a.x >= BUFFER_W and b.x >= BUFFER_W-1 then exit sub
        if a.y >= BUFFER_H and b.y >= BUFFER_W-1 then exit sub
        if c.x < 0 and d.x < 0 then exit sub
        if c.y < 0 and d.y < 0 then exit sub
        a.x = iif(a.x < 0, 0, iif(a.x >= BUFFER_W, BUFFER_W-1, a.x))
        a.y = iif(a.y < 0, 0, iif(a.y >= BUFFER_H, BUFFER_H-1, a.y))
        b.x = iif(b.x < 0, 0, iif(b.x >= BUFFER_W, BUFFER_W-1, b.x))
        b.y = iif(b.y < 0, 0, iif(b.y >= BUFFER_H, BUFFER_H-1, b.y))
        c.x = iif(c.x < 0, 0, iif(c.x >= BUFFER_W, BUFFER_W-1, c.x))
        c.y = iif(c.y < 0, 0, iif(c.y >= BUFFER_H, BUFFER_H-1, c.y))
        d.x = iif(d.x < 0, 0, iif(d.x >= BUFFER_W, BUFFER_W-1, d.x))
        d.y = iif(d.y < 0, 0, iif(d.y >= BUFFER_H, BUFFER_H-1, d.y))
        top = a.y
        btm = b.y
        h = (btm - top) + 1
        xl = a.x
        xr = c.x
        xli = lerpd(a.x, b.x, 1/h) - a.x
        xri = lerpd(c.x, d.x, 1/h) - c.x
        uvl = p
        uvr = r
        uvi = lerp(p, q, 1/h) - p
        uvj = lerp(r, s, 1/h) - r
        rowStart = buffer + top*pitch
        screenlock
        for y as integer = 0 to h-1
            w = abs(int(xr) - int(xl)) + 1
            uv = uvl
            uvx = lerp(uvl, uvr, 1/w) - uvl
            pixel = rowStart
            pixel += cast(_long_, int(xl))
            for x as integer = 0 to w-1
                *pixel = image.getPixel(uv.x, uv.y)
                uv += uvx
                pixel += 1
            next x
            xl += xli
            xr += xri
            uvl += uvi
            uvr += uvj
            rowStart += pitch
        next y
        screenunlock
    end if
end sub
