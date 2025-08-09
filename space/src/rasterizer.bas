' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "rasterizer.bi"
#include once "image32.bi"

declare sub drawFlatTrapezoid(a as Vector2, b as Vector2, c as Vector2, d as Vector2, colr as integer)

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
sub Rasterizer.drawFlatTri(a as Vector2, b as Vector2, c as Vector2, colr as integer)
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
sub Rasterizer.drawTexturedTri(a as Vector2, b as Vector2, c as Vector2, uva as Vector2, uvb as Vector2, uvc as Vector2, texture as any ptr)
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
'==============================================================================
'= PRIVATE SUBS
'==============================================================================
private sub drawFlatTrapezoid(a as Vector2, b as Vector2, c as Vector2, d as Vector2, colr as integer)
    dim as double ac, bd
    dim as double acx, bdx
    dim as integer y0, y1
    ac = a.x
    bd = b.x
    acx = (c.x - a.x) / (c.y - a.y)
    bdx = (d.x - b.x) / (d.y - b.y)
    y0 = a.y
    y1 = y0 + (c.y - a.y)
    for i as integer = y0 to y1
        line (int(ac), i)-(int(bd), i), colr
        ac += acx
        bd += bdx
    next i
end sub
