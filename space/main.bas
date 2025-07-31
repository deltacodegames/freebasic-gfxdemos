' -----------------------------------------------------------------------------
'  A Nameless 3D Polygonal Software Renderer & Rasterizer
'
'  Copyright (c) 2025 Joe King
'  Licensed under the MIT License.
'  See LICENSE file or https://opensource.org/licenses/MIT for details.
'
'
'  "It's six degrees of raw freedom!"
'      ~ Jimmy, 34 (Grand Rivers, KY)
'
'
'  Recommended build:
'    fbc64 %f -w all -gen gcc -O 3 -Wc -march=native
' -----------------------------------------------------------------------------

#cmdline "-i inc/"
#cmdline "-i src/inc/"

#cmdline "-b src/mouse2.bas"
#cmdline "-b src/vector2.bas"
#cmdline "-b src/vector3.bas"
#cmdline "-b src/orientation3.bas"
#cmdline "-b src/cframe3.bas"
#cmdline "-b src/face3.bas"
#cmdline "-b src/mesh3.bas"
#cmdline "-b src/object3.bas"
#cmdline "-b src/colorspace.bas"
#cmdline "-b src/particle3.bas"
#cmdline "-b src/screenmode.bas"
#cmdline "-b src/image32.bas"
#cmdline "-b gamesession.bas"
#cmdline "-b helpers.bas"

#include once "fbgfx.bi"
#include once "mouse2.bi"
#include once "vector2.bi"
#include once "vector3.bi"
#include once "orientation3.bi"
#include once "cframe3.bi"
#include once "face3.bi"
#include once "mesh3.bi"
#include once "object3.bi"
#include once "colorspace.bi"
#include once "particle3.bi"
#include once "gamesession.bi"
#include once "image32.bi"
#include once "screenmode.bi"
#include once "helpers.bi"
#include once "defines.bi"
#include once "main.bi"
using FB

#ifdef __FB_64BIT__
    #define _long_ longint
    #define _ulong_ ulongint
#else
    #define _long_ long
    #define _ulong_ ulong
#endif

const NUM_PARTICLES = 2000
const FIELD_SIZE = 9000

'------------------------------------------------------------------------------
' SCREEN STUFF
'------------------------------------------------------------------------------
dim shared as ScreenModeType ScreenMode

dim as GameSession game

'------------------------------------------------------------------------------
' THY HOLY TRINITY
'------------------------------------------------------------------------------
    init     game
    main     game
    shutdown game
'------------------------------------------------------------------------------
'------------------------------------------------------------------------------
'------------------------------------------------------------------------------
end

sub init(byref game as GameSession)

    dim as Object3 ptr anchor, asteroid, spaceship
    dim as Image32 image
    dim as any ptr buffer
    dim as long colr, value
    dim as long rc, gc, bc
    dim as double a, b, u, v

    game.renderMode  = RenderModes.Textured
    game.textureMode = TextureModes.Auto
    
    randomize
    initScreen()
    game.mouse.hide()
    game.mouse.setMode(Mouse2Mode.Viewport)

    game.navMode = NavigationModes.Orbit

    anchor    = game.addObject("anchor")
    asteroid  = game.addObject("asteroid", "data/mesh/rocks.obj")
    spaceship = game.addObject("spaceship", "data/mesh/spaceship3.obj")

    anchor->position = Vector3.Randomized() * 10
    anchor->hidden   = true
    
    asteroid->callback = @animateAsteroid
    buffer = game.addTexture(64, 64, "data/mesh/textures/asteroid64.bmp")
    if buffer then
        asteroid->mesh.textureFaces(buffer)
    end if
    
    spaceship->mesh.setFacesDoubleSided(true)
    buffer = game.addTexture(64, 64)
    if buffer then
        image.readInfo(buffer)
        for y as double = 0 to 63
            for x as double = 0 to 63
                a = x / 64
                b = y / 64
                u = sin(2*pi*a)
                v = cos(2*pi*a)
                colr  = ColorSpace2.SampleColor(Vector2(u, v)*(a+b), 2)
                value = -32 + (int(x) xor int(y))*2
                rc = clamp(rgb_r(colr) + value, 0, 255)
                gc = clamp(rgb_g(colr) + value, 0, 255)
                bc = clamp(rgb_b(colr) + value, 0, 255)
                colr = rgb(rc, gc, bc)
                image.plotPixel(x, y, colr)
            next x
        next y
        spaceship->mesh.textureFaces(buffer)
    end if
    for i as integer = 0 to NUM_PARTICLES-1
        game.addParticle(_
            Vector3(_
                FIELD_SIZE/2 * rnd*sin(2*pi*rnd),_
                FIELD_SIZE/2 * rnd*sin(2*pi*rnd),_
                FIELD_SIZE/2 * rnd*sin(2*pi*rnd) _
            ),_
            ColorSpace2.SampleColor(2*pi*rnd, rnd, 2)_
        )
    next i
end sub

sub shutdown(byref game as GameSession)
    game.mouse.Show()
end sub

sub initScreen()
    ScreenMode.readSettings()
    ScreenMode.flags = GFX_FULLSCREEN
    ScreenMode.pages = 2
    if ScreenMode.applySettings() then
        print "Failed to initialize graphics screen"
        sleep
        end
    end if
    dim as double ratiow = ScreenMode.ratiow
    dim as double ratioh = ScreenMode.ratioh
    ScreenMode.setView(-ratiow, 1, ratiow, -1)
    ScreenMode.applyView()
    screenset 1, 0
end sub

'=======================================================================
'= WORLD TRANSFORM
'=======================================================================
function localToWorld overload(position as vector3, world as CFrame3) as Vector3
    return Vector3(_
        dot(world.rightward, position),_
        dot(world.upward   , position),_
        dot(world.forward  , position) _
    )
end function

'=======================================================================
'= VIEW TRANSFORM
'=======================================================================
function worldToView(byval position as Vector3, camera as CFrame3, skipTranslation as boolean = false) as Vector3
    if not skipTranslation then
        position -= camera.position
    end if
    return Vector3(_
        dot(camera.rightward, position),_
        dot(camera.upward   , position),_
        dot(camera.forward  , position) _
    )
end function

'=======================================================================
'= SCREEN TRANSFORM
'----------------------------------------------------------------------
'- Calculate FOV as tan(degrees/2)
'- Default (1) is 90 degrees
'=======================================================================
function viewToScreen(vp as vector3, fov as double = 1) as Vector2
    dim as Vector2 v2
    vp.z *= fov
    v2.x = (vp.x / vp.z) * 2
    v2.y = (vp.y / vp.z) * 2
    return v2
end function

sub drawTexturedTri(a as Vector2, b as Vector2, c as Vector2, uva as Vector2, uvb as Vector2, uvc as Vector2, texture as Image32)
    dim as _long_ bpp = ScreenMode.bpp, pitch = ScreenMode.pitch
    dim as any ptr buffer, rowStart
    dim as ulong ptr pixel
    dim as Vector2 sideA, sideB, sideC
    dim as Vector2 toplft, btmrgt
    dim as Vector2 sau, sbu, scu
    dim as Vector2 bas, pro, p, n
    dim as integer x0, x1, y0, y1
    dim as double sal, sbl, scl
    dim as double u, v, w
    toplft.x = iif(a.x < b.x, iif(a.x < c.x, a.x, c.x), iif(b.x < c.x, b.x, c.x))
    toplft.y = iif(a.y < b.y, iif(a.y < c.y, a.y, c.y), iif(b.y < c.y, b.y, c.y))
    btmrgt.x = iif(a.x > b.x, iif(a.x > c.x, a.x, c.x), iif(b.x > c.x, b.x, c.x))
    btmrgt.y = iif(a.y > b.y, iif(a.y > c.y, a.y, c.y), iif(b.y > c.y, b.y, c.y))
    if toplft.x >= ScreenMode.w then exit sub
    if toplft.y >= ScreenMode.h then exit sub
    if btmrgt.x < 0 then exit sub
    if btmrgt.y < 0 then exit sub
    if toplft.x < 0 then toplft.x = 0
    if toplft.y < 0 then toplft.y = 0
    if btmrgt.x >= ScreenMode.w then btmrgt.x = ScreenMode.w-1
    if btmrgt.y >= ScreenMode.h then btmrgt.y = ScreenMode.h-1
    bas = normalize(c-b): pro = a-b: sideA = b + bas * dot(pro, bas) - a
    bas = normalize(a-c): pro = b-c: sideB = c + bas * dot(pro, bas) - b
    bas = normalize(b-a): pro = c-a: sideC = a + bas * dot(pro, bas) - c
    sau = sideA.normalized: sbu = sideB.normalized: scu = sideC.normalized
    sal = 1/sideA.length: sbl = 1/sideB.length: scl = 1/sideC.length
    x0 = int(toplft.x): x1 = int(btmrgt.x)
    y0 = int(toplft.y): y1 = int(btmrgt.y)
    buffer = screenptr
    if buffer <> 0 then
        rowStart = buffer + y0*pitch + x0*bpp
        screenlock
        for y as integer = y0 to y1
            pixel = rowStart
            for x as integer = x0 to x1
                p = Vector2(x, y)
                u = 1-dot(p-a, sau) * sal: if u < 0 or u > 1 then pixel += 1: continue for
                v = 1-dot(p-b, sbu) * sbl: if v < 0 or v > 1 then pixel += 1: continue for
                w = 1-dot(p-c, scu) * scl: if w < 0 or w > 1 then pixel += 1: continue for
                n = (uva*u + uvb*v + uvc*w)/3
                *pixel = texture.getPixel(u, v)
                pixel += 1
            next x
            rowStart += pitch
        next
        screenunlock
    end if
end sub
sub drawTexturedTriLowQ(a as Vector2, b as Vector2, c as Vector2, uva as Vector2, uvb as Vector2, uvc as Vector2, texture as Image32, quality as integer = 0, skipAreaCheck as boolean = false)
    dim as _long_ bpp = ScreenMode.bpp, pitch = ScreenMode.pitch
    dim as _long_ imgPitch, imgBpp, imgw, imgh
    dim as any ptr buffer = screenptr, row, start
    dim as any ptr imgBuffer, imgRowStart, imgPixelStart
    dim as ulong ptr pixel, imgPixel
    dim as integer area, screenArea, q
    dim as Vector2 sideA, sideB, sideC
    dim as Vector2 toplft, btmrgt
    dim as Vector2 sau, sbu, scu
    dim as Vector2 bas, pro, p, n
    dim as integer x0, x1, y0, y1
    dim as double sal, sbl, scl
    dim as double u, v, w
    dim as double ratio
    toplft.x = iif(a.x < b.x, iif(a.x < c.x, a.x, c.x), iif(b.x < c.x, b.x, c.x))
    toplft.y = iif(a.y < b.y, iif(a.y < c.y, a.y, c.y), iif(b.y < c.y, b.y, c.y))
    btmrgt.x = iif(a.x > b.x, iif(a.x > c.x, a.x, c.x), iif(b.x > c.x, b.x, c.x))
    btmrgt.y = iif(a.y > b.y, iif(a.y > c.y, a.y, c.y), iif(b.y > c.y, b.y, c.y))
    if toplft.x >= ScreenMode.w then exit sub
    if toplft.y >= ScreenMode.h then exit sub
    if btmrgt.x < 0 then exit sub
    if btmrgt.y < 0 then exit sub
    if toplft.x < 0 then toplft.x = 0
    if toplft.y < 0 then toplft.y = 0
    if btmrgt.x >= ScreenMode.w then btmrgt.x = ScreenMode.w-1
    if btmrgt.y >= ScreenMode.h then btmrgt.y = ScreenMode.h-1
    if skipAreaCheck = false then
        area = abs(int(toplft.x - btmrgt.x)) * abs(int(toplft.y - btmrgt.y))
        screenArea = ScreenMode.w * ScreenMode.h
        ratio = area / screenArea
        select case ratio
            case is > .125: quality = iif(quality < 3, 3, quality)
            case is > .5  : quality = iif(quality < 4, 4, quality)
        end select
        if quality > 4 then quality = 4
    end if
    q = 2^quality
    bas = normalize(c-b): pro = a-b: sideA = b + bas * dot(pro, bas) - a
    bas = normalize(a-c): pro = b-c: sideB = c + bas * dot(pro, bas) - b
    bas = normalize(b-a): pro = c-a: sideC = a + bas * dot(pro, bas) - c
    sau = sideA.normalized: sbu = sideB.normalized: scu = sideC.normalized
    sal = 1/sideA.length: sbl = 1/sideB.length: scl = 1/sideC.length
    x0 = int(toplft.x): x1 = int(btmrgt.x)
    y0 = int(toplft.y): y1 = int(btmrgt.y)
    x0 = (x0 \ q) * q
    x1 = (x1 \ q) * q
    y0 = (y0 \ q) * q
    y1 = (y1 \ q) * q
    imgw = (x1-x0+q)\q
    imgh = (y1-y0+q)\q
    imgBuffer = imagecreate(imgw, imgh)
    imageinfo imgBuffer, imgw, imgh, imgBpp, imgPitch, imgPixelStart
    start = buffer + y0*pitch + x0*bpp
    if buffer <> 0 and imgBuffer <> 0 then
        screenlock
        imgRowStart = imgPixelStart
        for y as integer = y0 to y1-q step q '- remove -q in future - band-aid for crash bug with very low quality
            imgPixel = imgRowStart
            for x as integer = x0 to x1 step q
                p = Vector2(x, y)
                u = 1-dot(p-a, sau) * sal: if u < 0 or u > 1 then imgPixel += 1: continue for
                v = 1-dot(p-b, sbu) * sbl: if v < 0 or v > 1 then imgPixel += 1: continue for
                w = 1-dot(p-c, scu) * scl: if w < 0 or w > 1 then imgPixel += 1: continue for
                n = (uva*u + uvb*v + uvc*w)/3
                *imgPixel = texture.getPixel(u, v)
                imgPixel += 1
            next x
            imgRowStart += imgPitch
        next
        row = start
        imgRowStart = imgPixelStart
        for i as integer = y0 to y1-q step q '- remove -q in future - band-aid for crash bug with very low quality
            for y as integer = 0 to q-1
                pixel = row
                imgPixel = imgRowStart
                for j as integer = x0 to x1 step q
                    if *imgPixel <> &hffff00ff then
                        for x as integer = 0 to q-1: *pixel = *imgPixel: pixel += 1: next x
                    else
                        pixel += q
                    end if
                    imgPixel += 1
                next j
                row += pitch
            next y
            imgRowStart += imgPitch
        next i
        screenunlock
        imagedestroy(imgBuffer)
    end if
end sub
sub drawTriSolidTop(a as Vector2, b as Vector2, c as Vector2, colr as integer)
    dim as double ab, ac
    dim as double abx, acx
    dim as integer y0, y1
    ab = a.x
    ac = a.x
    abx = (b.x - a.x) / (b.y - a.y)
    acx = (c.x - a.x) / (c.y - a.y)
    y0 = a.y
    y1 = y0 + int(b.y - a.y)
    for i as integer = y0 to y1
        line (int(ab), i)-(int(ac), i), colr
        ab += abx
        ac += acx
    next i
end sub
sub drawTriSolidBottom(a as Vector2, b as Vector2, c as Vector2, colr as integer)
    dim as double ac, bc
    dim as double acx, bcx
    dim as integer y0, y1
    ac = a.x
    bc = b.x
    acx = (c.x - a.x) / (c.y - a.y)
    bcx = (c.x - b.x) / (c.y - b.y)
    y0 = a.y
    y1 = y0 + (c.y - a.y)
    for i as integer = y0 to y1
        line (int(ac), i)-(int(bc), i), colr
        ac += acx
        bc += bcx
    next i
end sub
sub drawTriSolid(a as Vector2, b as Vector2, c as Vector2, colr as integer)
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
        drawTriSolidTop a, b, d, colr
        drawTriSolidBottom b, d, c, colr
    elseif a.y < b.y and b.y = c.y then
        drawTriSolidTop a, b, c, colr
    elseif a.y = b.y and b.y < c.y then
        drawTriSolidBottom a, b, c, colr
    else
        if a.x < b.x then swap a, b
        if a.x < c.x then swap a, c
        if b.x < c.x then swap b, c
        line(a.x, a.y)-(b.x, b.y), colr
    end if
end sub
sub renderFaceSolid(byref face as Face3, byref camera as CFrame3, byref world as CFrame3)
    dim as Vector2 a, b, c, pixels(ubound(face.vertexes))
    dim as Vector3 viewNormal, viewVertex(ubound(face.vertexes))
    dim as Vector3 worldNormal, worldVertex
    dim as integer colr, cr, cg, cb
    dim as double dt, value
    for i as integer = 0 to ubound(face.vertexes)
        worldVertex   = face.vertexes(i)
        viewVertex(i) = worldToView(worldVertex, camera)
        if viewVertex(i).z < 1 then
            exit sub
        end if
    next i
    cr = rgb_r(face.colr)
    cg = rgb_g(face.colr)
    cb = rgb_b(face.colr)
    dt = dot(face.normal, world.upward)
    value = 80 * dt
    colr = rgb(_
        clamp(cr+value, 0, 255),_
        clamp(cg+value, 0, 255),_
        clamp(cb+value, 0, 255) _
    )
    for i as integer = 0 to ubound(viewVertex)
        pixels(i) = viewToScreen(viewVertex(i))
    next i
    for i as integer = 1 to ubound(pixels) - 1
        a = pixels(0)
        b = pixels(i)
        c = pixels(i+1)
        a.x = pmap(a.x, 0): a.y = pmap(a.y, 1)
        b.x = pmap(b.x, 0): b.y = pmap(b.y, 1)
        c.x = pmap(c.x, 0): c.y = pmap(c.y, 1)
        ScreenMode.resetView()
        drawTriSolid(_
            Vector2(a.x, a.y),_
            Vector2(b.x, b.y),_
            Vector2(c.x, c.y),_
            colr _
        )
        ScreenMode.applyView()
    next i
end sub
sub renderFaceTextured(byref face as Face3, byref camera as CFrame3, byref world as CFrame3, quality as integer = -1)
    dim as Vector2 a, b, c, pixels(ubound(face.vertexes)), uvs(ubound(face.vertexes))
    dim as Vector3 viewNormal, viewVertex(ubound(face.vertexes))
    dim as Vector3 worldNormal, worldVertex
    dim as Image32 texture, shadedTexture
    dim as any ptr srcRow, dstRow
    dim as ulong ptr src, dst
    dim as ulong colr
    dim as long ubr, ubg, ubb
    dim as long value
    dim as double dist, dt
    dim as boolean skipAreaCheck
    dim as integer q = quality
    
    for i as integer = 0 to ubound(face.vertexes)
        worldVertex   = face.vertexes(i)
        viewVertex(i) = worldToView(worldVertex, camera)
        if viewVertex(i).z <= 0 then '- closer allow because draw sub clips
            exit sub
        end if
    next i

    if quality = -1 then
        dist = dot(camera.forward, face.position - camera.position)
        select case dist
            case is <  1.000: q = 5
            case is <  2.718: q = 4
            case is <  7.389: q = 3
            case is < 20.085: q = 2
            case is < 54.598: q = 1
            case else: q = 0
        end select
        skipAreaCheck = false
    else
        skipAreaCheck = true
    end if
    
    dt = dot(face.normal, world.upward)
    value = 80 * (-0.5 + dt)
    texture.readInfo(face.texture)
    shadedTexture = type(texture.w, texture.h)
    srcRow = texture.pixdata
    dstRow = shadedTexture.pixdata
    for y as integer = 0 to texture.h-1
        src = srcRow
        dst = dstRow
        for x as integer = 0 to texture.w-1
            colr = *src
            ubr = rgb_r(colr)
            ubg = rgb_g(colr)
            ubb = rgb_b(colr)
            colr = rgb(_
                clamp(ubr+value, 0, 255),_
                clamp(ubg+value, 0, 255),_
                clamp(ubb+value, 0, 255) _
            )
            *dst = colr
            src += 1
            dst += 1
        next x
        srcRow  += texture.pitch
        dstRow += shadedTexture.pitch
    next y
    
    for i as integer = 0 to ubound(viewVertex)
        pixels(i) = viewToScreen(viewVertex(i))
        uvs(i) = face.uvs(i)
    next i
    for i as integer = 1 to ubound(pixels) - 1
        a = pixels(0)
        b = pixels(i)
        c = pixels(i+1)
        a.x = pmap(a.x, 0): a.y = pmap(a.y, 1)
        b.x = pmap(b.x, 0): b.y = pmap(b.y, 1)
        c.x = pmap(c.x, 0): c.y = pmap(c.y, 1)
        ScreenMode.resetView()
        if q = 0 and skipAreaCheck = true then
            drawTexturedTri(_
                Vector2(a.x, a.y),_
                Vector2(b.x, b.y),_
                Vector2(c.x, c.y),_
                uvs(0), uvs(i), uvs(i+1),_
                shadedTexture _
            )
        else
            drawTexturedTriLowQ(_
                Vector2(a.x, a.y),_
                Vector2(b.x, b.y),_
                Vector2(c.x, c.y),_
                uvs(0), uvs(i), uvs(i+1),_
                shadedTexture,_
                q,_
                skipAreaCheck _
            )
        end if
        ScreenMode.applyView()
    next i
    'shadedTexture.free()
end sub
sub renderFaceWireframe(byref face as Face3, byref camera as CFrame3, byref world as CFrame3, wireColor as integer = &hffffff, vertexColor as integer = 0, normalColor as integer = 0)
    dim as Vector2 a, b, c, pixels(ubound(face.vertexes))
    dim as Vector3 viewVertex(ubound(face.vertexes))
    dim as Vector3 normal, position, worldVertex
    dim as integer style = &hffff
    if wireColor <> 0 or vertexColor <> 0 then
        for i as integer = 0 to ubound(face.vertexes)
            worldVertex   = face.vertexes(i)
            viewVertex(i) = worldToView(worldVertex, camera)
            if viewVertex(i).z < 1 then
                exit sub
            end if
        next i
    end if
    if face.doubleSided or normalColor <> 0 then
        normal = normalize(worldToView(face.normal, camera, true))
        position = worldToView(face.position, camera)
        style = iif(dot(normal, position) < 0, &hffff, &hf0f0)
    end if
    if wireColor <> 0 or vertexColor <> 0 then
        for i as integer = 0 to ubound(viewVertex)
            pixels(i) = viewToScreen(viewVertex(i))
        next i
        for i as integer = 0 to ubound(pixels)
            if i < ubound(pixels) then
                a = pixels(i)
                b = pixels(i+1)
            else
                a = pixels(i)
                b = pixels(0)
            end if
            if wireColor then
                line(a.x, a.y)-(b.x, b.y), wireColor, , style
            end if
            if vertexColor then
                line(a.x-.005, a.y-.005)-step(.01, .01), vertexColor, b, style
            end if
        next i
    end if
    if normalColor then
        if position.z > 1 and position.z + normal.z > 1 then
            a = viewToScreen(position)
            b = viewToScreen(position + normal)
            line(a.x, a.y)-(b.x, b.y), normalColor, , style
        end if
    end if
end sub
sub selectionSort(keys() as integer, vals() as double)
    dim as double max
    dim as integer selected
    for i as integer = 0 to ubound(vals)
        max = vals(i)
        selected = -1
        for j as integer = i + 1 to ubound(vals)
            if vals(j) > max then
                max = vals(j)
                selected = j
            end if
        next j
        if selected > -1 then
            swap keys(i), keys(selected)
            swap vals(i), vals(selected)
        end if
    next i
end sub
sub bottomUpMergeSort(keys() as integer, vals() as double)

    dim as double v0(any), v1(any), vSorted(any)
    dim as integer k0(any), k1(any), kSorted(any)
    dim as integer i, j, k, ub0, ub1
    
    if ubound(vals) <= 0 then
        exit sub
    end if
    
    ub0 = ((ubound(vals)+1) \ 2) - 1
    ub1 = ub0 + ((ubound(vals)+1) and 1)
    redim v0(ub0)
    redim k0(ub0)
    redim v1(ub1)
    redim k1(ub1)
    
    for i = 0 to ub0
        v0(i) = vals(i)
        k0(i) = keys(i)
    next i
    for i = 0 to ub1
        v1(i) = vals(1+i+ub0)
        k1(i) = keys(1+i+ub0)
    next i
    if ubound(v0) > 0 or ubound(v1) > 0 then
        bottomUpMergeSort k0(), v0()
        bottomUpMergeSort k1(), v1()
    end if
    
    redim vSorted(ubound(vals))
    redim kSorted(ubound(vals))
    i = 0: j = 0: k = 0
    while k <= ubound(vSorted)
        if v0(i) > v1(j) then
            vSorted(k) = v0(i)
            kSorted(k) = k0(i)
            i += 1
        else
            vSorted(k) = v1(j)
            kSorted(k) = k1(j)
            j += 1
        end if
        k += 1
        if i > ubound(v0) or j > ubound(v1) then
            exit while
        end if
    wend
    if i <= ubound(v0) then
        while i <= ubound(v0)
            vSorted(k) = v0(i)
            kSorted(k) = k0(i)
            i += 1
            k += 1
        wend
    elseif j <= ubound(v1) then
        while j <= ubound(v1)
            vSorted(k) = v1(j)
            kSorted(k) = k1(j)
            j += 1
            k += 1
        wend
    end if
    
    for i as integer = 0 to ubound(vals)
        vals(i) = vSorted(i)
        keys(i) = kSorted(i)
    next i
end sub
sub renderFaces(faces() as Face3, byref camera as CFrame3, byref world as CFrame3, renderMode as integer, textureMode as integer = -1)

    dim as Face3 sorted(any)
    dim as Vector3 normal, vertex
    dim as double vals(any)
    dim as integer keys(any)

    if renderMode = RenderModes.Wireframe then
        for i as integer = 0 to ubound(faces)
            renderFaceWireframe faces(i), camera, world, &hb0b0b0
        next i
        exit sub
    end if

    for i as integer = 0 to ubound(faces)
        vertex = worldToView(faces(i).position, camera)
        if vertex.z > 0 then
            if not faces(i).doubleSided then
                normal = normalize(worldToView(faces(i).normal, camera, true))
                if dot(normal, vertex) > 0 then
                    continue for
                end if
            end if
            array_append(keys, i)
            array_append(vals, vertex.length)
        end if
    next i

    bottomUpMergeSort keys(), vals()
    for i as integer = 0 to ubound(keys)
        array_append(sorted, faces(keys(i)))
    next i
    
    select case renderMode
    case RenderModes.Solid
        for i as integer = 0 to ubound(sorted)
            renderFaceSolid sorted(i), camera, world
        next i
    case RenderModes.Textured
        for i as integer = 0 to ubound(sorted)
            renderFaceTextured sorted(i), camera, world, textureMode
        next i
    end select
end sub
sub renderBspFaces(node as BspNode3 ptr, faces() as Face3, byref camera as CFrame3, byref world as CFrame3, renderMode as integer, textureMode as integer = -1)
    if node = 0 then exit sub
    dim as Vector3 normal, vertex, vewtex
    dim as Face3 face
    dim as double dt
    for i as integer = 0 to ubound(faces) '- todo: find more optimal solution
        if faces(i).id = node->faceId then
            face = faces(i)
            exit for
        end if
    next i
    if face.id = node->faceId then
        dt = dot(face.normal, camera.position - face.position)
        if dt > 0 then
            renderBspFaces node->behind, faces(), camera, world, renderMode, textureMode
            renderBspFaces node->infront, faces(), camera, world, renderMode, textureMode
        else
            renderBspFaces node->infront, faces(), camera, world, renderMode, textureMode
            renderBspFaces node->behind, faces(), camera, world, renderMode, textureMode
        end if
        select case renderMode
            case RenderModes.Solid   : renderFaceSolid face, camera, world
            case RenderModes.Textured
                if ubound(face.uvs) >= 0 and face.texture <> 0 then
                    renderFaceTextured face, camera, world, textureMode
                else
                    renderFaceSolid face, camera, world
                end if
            case RenderModes.Wireframe
                if dt > 0 then
                    renderFaceWireframe face, camera, world
                else
                    renderFaceWireframe face, camera, world
                end if
        end select
    end if
end sub
sub renderObjects(objects() as Object3 ptr, byref camera as CFrame3, byref world as CFrame3, renderMode as integer, textureMdoe as integer = -1)
    dim as Object3 o
    dim as Face3 face
    dim as Vector3 v
    dim as double dist
    for i as integer = 0 to ubound(objects)
        o = *objects(i)
        o.toWorld()
        renderFaces o.mesh.faces(), camera, world, renderMode, textureMdoe
        'renderBspFaces o.mesh.faces(), mesh, camera, world, textureMdoe
    next i
end sub
sub renderParticles(particles() as Particle3 ptr, byref camera as CFrame3)
    dim as Particle3 ptr particle
    dim as Vector2 coords
    dim as Vector3 vertex
    dim as double radius
    for i as integer = 0 to ubound(particles)
        particle = particles(i)
        vertex = worldToView(particle->position, camera)
        if vertex.z > 1 then
            coords = viewToScreen(vertex)
            radius = abs(1/vertex.z) * 0.2
            circle(coords.x, coords.y), radius, particle->getTwinkleColor()
        end if
    next i
end sub
sub animateObjects(byref game as GameSession)
    for i as integer = 0 to ubound(game.objects)
        dim byref o as Object3 = *game.objects(i)
        if o.callback then
            o.callback(o, game.camera, game.world, game.deltaTime)
        end if
        o.cframe *= CFrame3(o.linear * game.deltaTime, o.angular * game.deltaTime)
    next i
end sub

sub animateAsteroid(byref o as Object3, byref camera as CFrame3, byref world as CFrame3, deltaTime as double)
    dim as CFrame3 cf
    dim as Vector3 origin = Vector3.Zero
    if o.position = origin then
        o.angular = Vector3.Randomized() * 0.5
        o.position = Vector3.Randomized() * (50 + 150*rnd)
    else
        cf.position = o.position
        cf.lookAt(origin, world.upward)
        o.cframe.position += normalize(cf.rightward - cf.upward) * deltaTime * 5
    end if
end sub

sub setDebugLevel(level as integer, byref game as GameSession)

    static as integer wireframeCycle
    dim as integer flags = game.flags
    
    unsetFlag flags, DebugFlags.ShowAxes
    unsetFlag flags, DebugFlags.ShowNormals
    unsetFlag flags, DebugFlags.ShowVertexes

    if level > 0 and game.debugLevel = 0 then
        game.debugObject = game.activeObject
    end if
    
    select case level
        case 1
            if level = game.debugLevel then level = 0
        case 2
            if level = game.debugLevel then level = 0
        case 3
            if level <> game.debugLevel then
                wireframeCycle = 1
            else
                wireframeCycle += 1
                if wireframeCycle = 4 then
                    level = 0
                end if
            end if
            select case wireframeCycle
                case 1: setFlag flags, DebugFlags.ShowAxes
                case 2: setFlag flags, DebugFlags.ShowVertexes
                case 3: setFlag flags, DebugFlags.ShowNormals
            end select
        case 4
            if level <> game.debugLevel then
                setFlag flags, DebugFlags.ShowAxes
            else
                level = 0
            end if
    end select

    select case level
        case 0: game.renderMode = RenderModes.Textured
        case 1: game.renderMode = RenderModes.Textured
        case 2: game.renderMode = RenderModes.Solid
        case 3: game.renderMode = RenderModes.Wireframe
        case 4: game.renderMode = RenderModes.None
    end select
    
    game.debugLevel = level
    game.debugFlags = flags
    
end sub

'==============================================================================
'= START
'==============================================================================
sub main(game as GameSession)

    dim as Object3 ptr activeObject, anchor, asteroid, spaceship

    dim byref as NavigationModes navMode     = game.navMode
    dim byref as RenderModes     renderMode  = game.renderMode
    dim byref as TextureModes    textureMode = game.textureMode
    dim byref as integer         debugLevel  = game.debugLevel
    
    dim as double deltaTime, frameStartTime
    dim as integer keyWait = -1

    anchor    = game.findObject(   "anchor")
    asteroid  = game.findObject( "asteroid")
    spaceship = game.findObject("spaceship")
    
    select case navMode
        case NavigationModes.Fly   : game.activeObject = anchor
        case NavigationModes.Follow: game.activeObject = spaceship
        case NavigationModes.Orbit : game.activeObject = spaceship
    end select
    
    activeObject = game.activeObject
    
    frameStartTime = timer
    while not multikey(SC_ESCAPE)

        select case navMode
            case NavigationModes.Fly   : handleFlyInput    game
            case NavigationModes.Follow: handleFollowInput game
            case NavigationModes.Orbit : handleOrbitInput  game
        end select
        unsetFlag(game.flags, GameFlags.ResetMode)

        animateObjects game
        renderFrame    game
        renderUI       game
        
        if debugLevel <> 0 then
            printDebugInfo game
            if hasFlag(game.debugFlags, DebugFlags.ShowAxes    ) then drawAxes     game
            if hasFlag(game.debugFlags, DebugFlags.ShowVertexes) then drawVertexes game
            if hasFlag(game.debugFlags, DebugFlags.ShowNormals ) then drawNormals  game
        end if

        keydown(SC_F1, keyWait, setDebugLevel(1, game))
        keydown(SC_F2, keyWait, setDebugLevel(2, game))
        keydown(SC_F3, keyWait, setDebugLevel(3, game))
        keydown(SC_F4, keyWait, setDebugLevel(4, game))
        
        static as integer firstTime = 0
        '- docking station
        if firstTime then
            firstTime = 0
            dim as Face3 face
            face.normal   = type(0,0,1).normalized()
            face.position = type(1,0,0)
            activeObject->mesh = activeObject->mesh.splitMesh(face.normal, face.position)
            ' destroy old mesh (mainly texture memory)
        end if
        
        screencopy 1, 0

        deltaTime      = timer - frameStartTime
        frameStartTime = timer

        game.deltaTime = deltaTime
        game.mouse.update

        if renderMode = RenderModes.Textured then
            if multikey(SC_0) then textureMode = 0
            if multikey(SC_9) then textureMode = 1
            if multikey(SC_8) then textureMode = 2
            if multikey(SC_7) then textureMode = 3
            if multikey(SC_6) then textureMode = 4
        end if

        if multikey(SC_O) then activeObject->cframe = CFrame3()
        if multikey(SC_X) then activeObject->cframe.orientation = Orientation3() * Vector3(pi/2, 0, 0)
        if multikey(SC_Y) then activeObject->cframe.orientation = Orientation3() * Vector3(0, pi/2, 0)
        if multikey(SC_Z) then activeObject->cframe.orientation = Orientation3() * Vector3(0, 0, pi/2)

        keydown(SC_1, keyWait, navMode = NavigationModes.Fly   : game.activeObject = anchor   : setFlag(game.flags, GameFlags.ResetMode))
        keydown(SC_2, keyWait, navMode = NavigationModes.Follow: game.activeObject = spaceship: setFlag(game.flags, GameFlags.ResetMode))
        keydown(SC_3, keyWait, navMode = NavigationModes.Orbit : game.activeObject = spaceship: setFlag(game.flags, GameFlags.ResetMode))

        if multikey(SC_CONTROL) <> 0 or game.mouse.middleDown then
            game.camera.lookAt(spaceship->position, spaceship->upward)
        end if
    wend
end sub

sub renderFrame(byref game as GameSession)
    dim as CFrame3 cam = game.camera
    if multikey(SC_BACKSPACE) then cam.orientation *= Vector3(0, rad(180), 0)
    cls
    renderParticles(game.particles(), cam)
    renderObjects(game.objects(), cam, game.world, game.renderMode, game.textureMode)
end sub

sub renderRadar(byref game as GameSession)

    static as boolean drawRadar = true
    static as integer keyWait = -1

    dim as Object3 ptr o, active = game.activeObject
    dim as Vector3 v

    keydown(SC_M, keyWait, drawRadar = not drawRadar)
    if drawRadar then
        ScreenMode.resetView
        dim as integer w = ScreenMode.w/10, h = (ScreenMode.h*ScreenMode.ratiow)/10, b = 1
        dim as integer cx = w\2, cy = h\2
        dim as integer offsetx =  active->position.x mod 500
        dim as integer offsetz = -active->position.z mod 500
        offsetx \= 10
        offsetz \= 10
        view (ScreenMode.w-1-w, 1)-(ScreenMode.w-2, h+1), &h112244, &hb0b0b0
        window (-100, 100)-(100, -100)
        for y as integer = -100+offsetz to 100+offsetz step 50
            for x as integer = -100+offsetx to 100+offsetx step 50
                line(-x, y)-(x, y), &h405080
                line(x, -y)-(x, y), &h405080
            next x
        next y
        for i as integer = 0 to ubound(game.objects)
            o = game.objects(i)
            if o = active then continue for
            if o->hidden then continue for
            v = o->position
            v = active->vectorToLocal(v)
            v /= 10
            circle (v.x, v.z), 3, &hffffff
            drawTriSolid(_
                Vector2(v.x, v.z + v.y),_
                Vector2(v.x + 2, v.z - v.y),_
                Vector2(v.x - 2, v.z - v.y),_
                &hff0000 _
            )
        next i
        line (-100, 0)-(100, 0), &h808080, , &hcccc
        line (0, -100)-(0, 100), &h808080, , &hcccc
        circle (0, 0), 3, &hffff00
        view
        ScreenMode.applyView
    end if
end sub

sub renderUI(byref game as GameSession)
    renderRadar game
    if game.navMode = NavigationModes.Fly then
        drawReticle game.mouse
    end if
    drawMouseCursor game.mouse
end sub

sub drawReticle(byref mouse as Mouse2, reticleColor as integer = &h808080, arrowColor as integer = &hd0b000)
    dim as Vector2 m = type(mouse.x, mouse.y)
    '- draw center circle
    dim as double fr = 0.11
    dim as double stp = PI/3
    dim as double start = atan2(m.y, m.x)
    if start < 0 then start += 2*PI
    for r as double = start-2*PI-stp/4 to 2*PI step stp
        if r >= 0 then
            circle(0, 0), fr, reticleColor, r, r+stp/2
        end if
    next r
    '- draw directionol arrow
    dim as double sz
    dim as integer colr = arrowColor
    dim as Vector2 a, b
    if mouse.buttons > 0 then
        sz = fr/4
        a = normalize(m)*fr*1.15
        b = normalize(a).rotatedLeft()*sz
        line(a.x, a.y)-step(b.x, b.y), colr
        b = normalize(b).rotatedRight().rotated(rad(-30))*sz*2
        line -step(b.x, b.y), colr
        b = normalize(b).rotated(rad(-120))*sz*2
        line -step(b.x, b.y), colr
        b = normalize(b).rotated(rad(-120))*sz
        line -step(b.x, b.y), colr
    end if
end sub

sub drawAxes(byref game as GameSession)
    dim as Object3 ptr o
    dim as Vector3 p, v(2)
    dim as Vector2 a, b
    dim as integer colors(2) = {_
        DebugColors.AxisX,_
        DebugColors.AxisY,_
        DebugColors.AxisZ _
    }
    for i as integer = 0 to ubound(game.objects)
        o = game.objects(i)
        p = worldToView(o->position, game.camera)
        if p.z > 1 then
            v(0) = worldToView(o->position + o->rightward * 2, game.camera)
            v(1) = worldToView(o->position + o->upward    * 2, game.camera)
            v(2) = worldToView(o->position + o->forward   * 2, game.camera)
            a = viewToScreen(p)
            for j as integer = 0 to ubound(v)
                if v(j).z > 0 then
                    b = viewToScreen(v(j))
                    line (a.x, a.y)-(b.x, b.y), colors(j), , &hcccc
                    draw string (b.x, b.y), iif(j = 0, "X", iif(j = 1, "Y", "Z"))
                end if
            next j
            draw string (a.x, a.y), o->sid
        end if
    next i
end sub

sub drawNormals(byref game as GameSession)
    dim as Object3 ptr debugObject = game.debugObject
    dim as Face3 face
    if debugObject then
        for i as integer = 0 to ubound(debugObject->mesh.faces)
            face = debugObject->mesh.faces(i)
            face.normal = debugObject->vectorToWorld(face.normal)
            face.position = debugObject->pointToWorld(face.position)
            renderFaceWireframe face, game.camera, game.world, 0, , &hd00000
        next i
    end if
end sub

sub drawVertexes(byref game as GameSession)
    dim as Object3 ptr debugObject = game.debugObject
    dim as Face3 face
    dim as Vector3 vertex
    if debugObject then
        for i as integer = 0 to ubound(debugObject->mesh.faces)
            face = debugObject->mesh.faces(i)
            for j as integer = 0 to ubound(face.vertexes)
                face.vertexes(j) = debugObject->pointToWorld(face.vertexes(j))
            next j
            renderFaceWireframe face, game.camera, game.world, 0, &h00d000
        next i
    end if
end sub

sub drawMouseCursor(byref mouse as Mouse2)
    dim as ulong ants = &b11000011110000111100001111000011 shr int(frac(timer*1.5)*16)
    dim as Vector2 m = type(mouse.x, mouse.y)
    dim as Vector2 a = m, b
    dim as double r = 0.076
    b = Vector2(rad(-75))*r
    line(a.x, a.y)-step(b.x, b.y), &hf0f0f0, , ants
    b = b.rotated(rad(105))*0.8
    line -step(b.x, b.y), &hf0f0f0, , ants
    line -(a.x, a.y), &hf0f0f0, , ants
end sub

sub fpsUpdate (byref fps as integer)
    static as double fpsResetTime = -1
    static as integer frameCount
    frameCount += 1
    if fpsResetTime = -1 then
        fpsResetTime = timer + 1
    elseif timer > fpsResetTime then
        fpsResetTime = timer + 1
        fps = frameCount
        frameCount = 0
    end if
end sub


sub printDebugInfo(byref game as GameSession)

    if game.activeObject then
        printStringBlock( 1, 1, getOrientationStats(game.activeObject->cframe), "ORIENTATION", "_", "")
        printStringBlock(10, 1,    getLocationStats(game.activeObject->cframe),    "LOCATION", "_", "")
    end if

    dim as integer row = 15
    dim as string buffer = space(21)
    select case game.renderMode
        case RenderModes.Solid    : mid(buffer, 2) = "Solid"
        case RenderModes.Textured : mid(buffer, 2) = "Texture"
        case RenderModes.Wireframe: mid(buffer, 2) = "Wireframe"
    end select
    printStringBlock(row, 1, buffer, "RENDER MODE", "_", "")

    if game.renderMode = RenderModes.Textured then
        buffer = space(21)
        if game.textureMode = TextureModes.Auto then
            mid(buffer,  2) = "Auto"
        else
            select case game.textureMode
                case    TextureModes.Best : mid(buffer,  2) = str(game.textureMode) + " Best"
                case    TextureModes.Worst: mid(buffer,  2) = str(game.textureMode) + " Worst"
                case else: mid(buffer,  2) = str(game.textureMode)
            end select
        end if
        row += 5
        printStringBlock(row, 1, buffer, "QUALITY", "_", "")
    end if
    
    static as integer fps
    fpsUpdate fps
    buffer = space(21)
    mid(buffer, 1) = format_decimal(fps, 1)
    row += 5
    printStringBlock(row, 1, buffer, "FPS", "_", "")
end sub

sub handleFlyInput(byref game as GameSession)

    static as boolean firstTime = true

    dim as Vector3 angularGoal, linearGoal
    dim as double mx, my

    dim byref as Mouse2 mouse   = game.mouse
    dim byref as CFrame3 camera = game.camera
    dim as Object3 ptr active   = game.activeObject
    dim as double deltaTime     = game.deltaTime
    
    if firstTime or hasFlag(game.flags, GameFlags.ResetMode) then
        firstTime = false
        active->cframe = camera
    end if

    mx = mouse.x
    my = mouse.y * ScreenMode.ratiow
    mx *= 1.5
    my *= 1.5

    if mouse.leftDown then
        angularGoal.y  = mx
        angularGoal.x -= my
    elseif mouse.rightDown then
        dim as Vector2 m = type(mx, my)
        m = rotate(m, atan2(angularGoal.z, angularGoal.x))
        angularGoal.x -= my
        angularGoal.z -= mx
    end if

    if multikey(SC_W     ) then linearGoal.z =  1
    if multikey(SC_S     ) then linearGoal.z = -1
    if multikey(SC_D     ) then linearGoal.x =  1
    if multikey(SC_A     ) then linearGoal.x = -1
    if multikey(SC_SPACE ) then linearGoal.y =  1
    if multikey(SC_LSHIFT) then linearGoal.y = -1
    

    if multikey(SC_UP   ) then angularGoal.x = -1
    if multikey(SC_DOWN ) then angularGoal.x =  1
    if multikey(SC_RIGHT) then angularGoal.y =  1
    if multikey(SC_LEFT ) then angularGoal.y = -1
    if multikey(SC_E    ) then angularGoal.z = -1
    if multikey(SC_Q    ) then angularGoal.z =  1

    if linearGoal.length > 0 then
        linearGoal = normalize(dot(camera.orientation.matrix(), linearGoal)) * 15
    end if
    
    active->linear  = lerpexp(active->linear, linearGoal, deltaTime)
    active->angular = lerpexp(active->angular, angularGoal, deltaTime)
    camera = active->cframe
end sub

sub handleFollowInput(byref game as GameSession)

    dim as Vector3 angularGoal, linearGoal, thrustGoal
    static as Vector3 thrust
    static as boolean firstTime = true

    dim byref as Mouse2 mouse   = game.mouse
    dim byref as CFrame3 camera = game.camera
    dim as Object3 ptr active   = game.activeObject
    dim as double deltaTime     = game.deltaTime
    
    static as integer keyWait = -1
    static as Vector3 distances(4) = {_
        type(0, 1.5, 6),_
        type(0,  3, 12),_
        type(0,  6, 24),_
        type(0, 15, 36),_
        type(0, 24, 96)_
    }
    static as integer distanceId = 0

    if firstTime or hasFlag(game.flags, GameFlags.ResetMode) then
        firstTime = false
        distanceId = 0
    end if

    if multikey(SC_TAB) and keyWait = -1 then
        keyWait = SC_TAB
        distanceId += 1
        if distanceId > ubound(distances) then
            distanceId = lbound(distances)
        end if
    elseif not multikey(SC_TAB) and keyWait = SC_TAB then
        keyWait = -1
    end if

    if multikey(SC_W     ) then thrustGoal.z =  100
    if multikey(SC_S     ) then thrustGoal.z = -20
    if multikey(SC_D     ) then thrustGoal.x =  10
    if multikey(SC_A     ) then thrustGoal.x = -10
    if multikey(SC_SPACE ) then thrustGoal.y =  10
    if multikey(SC_LSHIFT) then thrustGoal.y = -10

    if multikey(SC_UP   ) then angularGoal.x =  1
    if multikey(SC_DOWN ) then angularGoal.x = -1
    if multikey(SC_RIGHT) then angularGoal.y =  1
    if multikey(SC_LEFT ) then angularGoal.y = -1
    if multikey(SC_E    ) then angularGoal.z = -1
    if multikey(SC_Q    ) then angularGoal.z =  1

    if linearGoal.length > 0 then
        linearGoal = normalize(_
            active->rightward * linearGoal.x + _
            active->upward    * linearGoal.y + _
            active->forward   * linearGoal.z _
        )
    end if

    if thrust.z >= 0 and thrustGoal.z <> 0 then
        if thrustGoal.z > thrust.z then
            thrust.z = lerp(thrust.z, thrustGoal.z, deltaTime/3)
        else
            thrust.z = lerp(thrust.z, thrustGoal.z, deltaTime)
        end if
    elseif thrust.z <= 0 then
        thrust.z = lerp(thrust.z, thrustGoal.z, deltaTime)
    end if
    thrust.x = lerpexp(thrust.x, thrustGoal.x, deltaTime)
    thrust.y = lerpexp(thrust.y, thrustGoal.y, deltaTime)

    active->linear = active->vectorToWorld(thrust)
    
    'active->linear  = lerpexp(active->linear, linearGoal, deltaTime)
    active->angular = lerpexp(active->angular, angularGoal, deltaTime)

    dim as Vector3 followDistance = distances(distanceId)
    dim as CFrame3 cameraGoal = type(_
        active->position - active->forward * followDistance.z + active->upward * followDistance.y,_
        active->orientation _
    )
    'cameraGoal.orientation = Orientation3.look(active->forward, -active->upward)
    camera = lerpexp(camera, cameraGoal, deltaTime * sqr(1+sin(thrust.z/100)))
end sub

sub handleOrbitInput(byref game as GameSession)

    static as Vector3 offset, upward
    static as boolean firstTime = true

    dim byref as Mouse2 mouse   = game.mouse
    dim byref as CFrame3 camera = game.camera
    dim as Object3 ptr active   = game.activeObject
    dim as double deltaTime     = game.deltaTime

    if firstTime or hasFlag(game.flags, GameFlags.ResetMode) then
        firstTime = false
        active->angular = Vector3.Randomized()
        offset = Vector3.Randomized() * (15 + 30*rnd)
        camera.position = active->position + active->vectorToLocal(offset)
        upward = Vector3.Randomized()
    end if
    
    camera.lookAt(active->position, upward)
    if mouse.leftDown then
        camera.position += camera.rightward * mouse.dragX * deltaTime * 30
        camera.position += camera.upward * mouse.dragY * deltaTime * 30
    else
        camera.position -= camera.rightward * deltaTime * 3
    end if
    
end sub
