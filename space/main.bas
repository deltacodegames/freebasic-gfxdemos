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
#cmdline "-b src/rasterizer.bas"
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
#include once "rasterizer.bi"
#include once "helpers.bi"
#include once "defines.bi"
#include once "main.bi"
using fb

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
    dim as integer textureId

    game.bgColor     = &h000007
    game.renderMode  = RenderModes.Textured
    game.textureMode = TextureModes.Auto
    
    randomize
    initScreen()
    Rasterizer.init()
    
    game.mouse.hide()
    game.mouse.setMode(Mouse2Mode.Viewport)
    game.navMode = NavigationModes.Orbit

    anchor    = game.addObject("anchor")
    asteroid  = game.addObject("asteroid", game.loadMesh("data/mesh/rocks.obj"))
    spaceship = game.addObject("spaceship", game.loadMesh("data/mesh/spaceship3.obj"))

    anchor->position = Vector3.Randomized() * 10
    anchor->visible  = false
    
    asteroid->callback = @animateAsteroid
    textureId = game.addTexture(64, 64, "data/mesh/textures/asteroid64.bmp")
    if game.getTexture(textureId) then
        game.generateShades(textureId)
        for i as integer = 0 to ubound(game.shades, 2)
            asteroid->mesh->addTexture(game.getShade(textureId, i))
        next i
    end if
    
    spaceship->mesh->doubleSided = true
    textureId = game.addTexture(64, 64, "data/mesh/textures/spaceship3.bmp")
    if game.getTexture(textureId) then
        game.generateShades(textureId)
        for i as integer = 0 to ubound(game.shades, 2)
            spaceship->mesh->addTexture(game.getShade(textureId, i))
        next i
    end if

    'ScreenMode.resetView()
    'dim as Face3 face
    'dim as Vector2 uv, n, p, a, b
    'dim as boolean inside, inside2
    'dim as any ptr buffer = imagecreate(64, 64)
    'line buffer, (0, 0)-(63, 63), &hff00ff, bf
    'for i as integer = 0 to ubound(spaceship->mesh->faces)
        'face = spaceship->mesh->faces(i)
        'for y as integer = 0 to 63
            'for x as integer = 0 to 63
                'p = Vector2((x+0.5)/64, (y+0.5)/64)
                'inside = true
                'for j as integer = 0 to ubound(face.uvs)
                    'a = face.uvs(j)
                    'b = iif(j < ubound(face.uvs), face.uvs(j+1), face.uvs(0))
                    'n = normalize((b-a).rotated(-pi/2))
                    'if dot(n, p-a) < 0 then
                        'inside = false
                        'exit for
                    'end if
                'next j
                'if inside then
                    'pset buffer, (x, y), face.colr
                'end if
            'next x
        'next y
    'next i
    'for i as integer = 0 to ubound(spaceship->mesh->faces)
        'face = spaceship->mesh->faces(i)
        'for y as integer = 0 to 63
            'for x as integer = 0 to 63
                'if point(x, y, buffer) = &hff00ff then
                    'inside = true
                    'for j as integer = 0 to ubound(face.uvs)
                        'a = face.uvs(j)
                        'b = iif(j < ubound(face.uvs), face.uvs(j+1), face.uvs(0))
                        'n = normalize((b-a).rotated(-pi/2))
                        'inside2 = false
                        'if dot(n, Vector2((x+0.001)/64, (y+0.001)/64)-a) >= 0 then inside2 = true
                        'if dot(n, Vector2((x+0.999)/64, (y+0.001)/64)-a) >= 0 then inside2 = true
                        'if dot(n, Vector2((x+0.001)/64, (y+0.999)/64)-a) >= 0 then inside2 = true
                        'if dot(n, Vector2((x+0.999)/64, (y+0.999)/64)-a) >= 0 then inside2 = true
                        'if inside2 = false then
                            'inside = false
                            'exit for
                        'end if
                    'next j
                    'if inside then
                        'pse6t buffer, (x, y), 0
                    'end if
                'end if
            'next x
        'next y
    'next i
    'bsave "uvmap.bmp", buffer
    'textureId = game.addTexture(64, 64)
    'if game.getTexture(textureId) then
    '    image.readInfo(game.getTexture(textureId))
    '    for y as double = 0 to 63
    '        for x as double = 0 to 63
    '            a = x / 64
    '            b = y / 64
    '            u = sin(2*pi*a)
    '            v = cos(2*pi*a)
    '            colr  = ColorSpace2.SampleColor(Vector2(u, v)*(a+b), 2)
    '            value = -32 + (int(x) xor int(y))*2
    '            rc = clamp(rgb_r(colr) + value, 0, 255)
    '            gc = clamp(rgb_g(colr) + value, 0, 255)
    '            bc = clamp(rgb_b(colr) + value, 0, 255)
    '            colr = rgb(rc, gc, bc)
    '            image.putPixel(x, y, colr)
    '        next x
    '    next y
    '    game.generateShades(textureId)
    '    for i as integer = 0 to ubound(game.shades, 2)
    '        spaceship->mesh->addTexture(game.getShade(textureId, i))
    '    next i
    'end if
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
    game.free()
    Rasterizer.shutdown()
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
    return (Vector2(vp.x, vp.y) / (vp.z * fov)) * 2
end function

sub clipViewPoly3NearZ overload(vertexes() as Vector3, clippedVerts() as Vector3, byref camera as CFrame3, index as integer = 0)
    dim as Vector3 normals(0) = { Vector3(0, 0, 1) }
    dim as Vector3 positions(0) = { Vector3(0, 0, 1/4) }
    dim as Vector3 normal = normalize(normals(index))
    dim as Vector3 a, b, c, newVerts(any), position, u3, v3, w3
    dim as double dta, dtb

    position = positions(index)
    
    for i as integer = 0 to ubound(vertexes)
        a = vertexes(i)
        b = iif(i < ubound(vertexes), vertexes(i+1), vertexes(0))
        dta = dot(normal, a - position)
        dtb = dot(normal, b - position)
        if dta >= 0 then
            array_append(newVerts, a)
            if dtb < 0 then
                c = a + (b - a) * dta / (dta + abs(dtb))
                array_append(newVerts, c)
            end if
        elseif dtb >= 0 then
            c = b + (a - b) * dtb / (dtb + abs(dta))
            array_append(newVerts, c)
        end if
    next i
    if index < ubound(normals) then
        clipViewPoly3NearZ newVerts(), clippedVerts(), camera, index + 1
    else
        for i as integer = 0 to ubound(newVerts)
            array_append(clippedVerts, newVerts(i))
        next i
    end if
end sub

sub clipViewPoly3NearZ overload(vertexes() as Vector3, uvs() as Vector2, clippedVerts() as Vector3, clippedUvs() as Vector2, byref camera as CFrame3, index as integer = 0)
    dim as Vector3 normals(0) = { Vector3(0, 0, 1) }
    dim as Vector3 positions(0) = { Vector3(0, 0, 1/4) }
    dim as Vector3 normal = normalize(normals(index))
    dim as Vector3 a, b, c, newVerts(any), position, u3, v3, w3
    dim as Vector2 newUvs(any), u, v, w
    dim as double dta, dtb

    position = positions(index)
    
    for i as integer = 0 to ubound(vertexes)
        a = vertexes(i)
        b = iif(i < ubound(vertexes), vertexes(i+1), vertexes(0))
        u = uvs(i)
        v = iif(i < ubound(uvs), uvs(i+1), uvs(0))
        dta = dot(normal, a - position)
        dtb = dot(normal, b - position)
        if dta >= 0 then
            array_append(newVerts, a)
            array_append(newUvs  , u)
            if dtb < 0 then
                c = a + (b - a) * dta / (dta + abs(dtb))
                w = u + (v - u) * dta / (dta + abs(dtb))
                array_append(newVerts, c)
                array_append(newUvs  , w)
            end if
        elseif dtb >= 0 then
            c = b + (a - b) * dtb / (dtb + abs(dta))
            w = v + (u - v) * dtb / (dtb + abs(dta))
            array_append(newVerts, c)
            array_append(newUvs  , w)
        end if
    next i
    if index < ubound(normals) then
        clipViewPoly3NearZ newVerts(), newUvs(), clippedVerts(), clippedUvs(), camera, index + 1
    else
        for i as integer = 0 to ubound(newVerts)
            array_append(clippedVerts, newVerts(i))
            array_append(clippedUvs  , newUvs(i))
        next i
    end if
end sub

sub renderFaceSolid(byref face as Face3, byref camera as CFrame3, byref world as CFrame3)
    dim as Vector2 a, b, c, pixels(any)
    dim as Vector3 clipped(any), vertexes(any)
    dim as integer colr, cr, cg, cb
    dim as double dt, value

    redim vertexes(ubound(face.vertexes))
    for i as integer = 0 to ubound(face.vertexes)
        vertexes(i) = worldToView(face.vertexes(i), camera)
    next i
    
    clipViewPoly3NearZ vertexes(), clipped(), camera

    if ubound(clipped) >= 2 then
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
        redim pixels(ubound(clipped))
        for i as integer = 0 to ubound(clipped)
            pixels(i) = viewToScreen(clipped(i))
            pixels(i).x = pmap(pixels(i).x, 0)
            pixels(i).y = pmap(pixels(i).y, 1)
        next i
        ScreenMode.resetView()
        Rasterizer.drawFlatPoly pixels(), colr
        ScreenMode.applyView()
    end if
end sub
sub renderFaceTextured(byref face as Face3, byref camera as CFrame3, byref world as CFrame3, textures() as any ptr, quality as integer = -1)
    dim as Vector2 clippedUvs(any), pixels(any)
    dim as Vector3 clippedVerts(any), vertexes(any)
    dim as any ptr texture
    dim as double dist, dt
    dim as integer q = quality
    
    redim vertexes(ubound(face.vertexes))
    for i as integer = 0 to ubound(face.vertexes)
        vertexes(i) = worldToView(face.vertexes(i), camera)
    next i
    
    clipViewPoly3NearZ vertexes(), face.uvs(), clippedVerts(), clippedUvs(), camera

    if ubound(clippedVerts) >= 2 then
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
        end if
        if ubound(textures) < 0 then exit sub
        dt = dot(face.normal, world.upward): dt = clamp(dt, -1, 1)
        texture = textures(int((0.5 + dt * 0.5) * ubound(textures)))
        if texture = 0 then exit sub
        redim pixels(ubound(clippedVerts))
        for i as integer = 0 to ubound(clippedVerts)
            pixels(i) = viewToScreen(clippedVerts(i))
            pixels(i).x = pmap(pixels(i).x, 0)
            pixels(i).y = pmap(pixels(i).y, 1)
        next i
        ScreenMode.resetView()
        Rasterizer.drawTexturedPoly pixels(), clippedUvs(), texture
        ScreenMode.applyView()
    end if
end sub
sub renderFaceTexturedPC(byref face as Face3, byref camera as CFrame3, byref world as CFrame3, textures() as any ptr, quality as integer = -1)
    dim as Vector2 clippedUvs(any), pixels(any)
    dim as Vector3 clippedVerts(any), uvs(any), vertexes(any)
    dim as any ptr texture
    dim as double dist, dt
    dim as integer q = quality
    
    redim vertexes(ubound(face.vertexes))
    for i as integer = 0 to ubound(face.vertexes)
        vertexes(i) = worldToView(face.vertexes(i), camera)
    next i
    
    clipViewPoly3NearZ vertexes(), face.uvs(), clippedVerts(), clippedUvs(), camera

    if ubound(clippedVerts) >= 2 then
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
        end if
        if ubound(textures) < 0 then exit sub
        dt = dot(face.normal, world.upward): dt = clamp(dt, -1, 1)
        texture = textures(int((0.5 + dt * 0.5) * ubound(textures)))
        if texture = 0 then exit sub
        redim pixels(ubound(clippedVerts))
        redim uvs(ubound(clippedVerts))
        for i as integer = 0 to ubound(clippedVerts)
            pixels(i) = viewToScreen(clippedVerts(i))
            pixels(i).x = pmap(pixels(i).x, 0)
            pixels(i).y = pmap(pixels(i).y, 1)
            uvs(i).x = clippedUvs(i).x
            uvs(i).y = clippedUvs(i).y
            uvs(i).z = clippedVerts(i).z
        next i
        ScreenMode.resetView()
        Rasterizer.drawTexturedPoly pixels(), uvs(), texture
        ScreenMode.applyView()
    end if
end sub
sub renderFaceWireframe(byref face as Face3, byref camera as CFrame3, byref world as CFrame3, wireColor as integer = &hffffff, vertexColor as integer = 0, normalColor as integer = 0, doubleSided as boolean = false)
    dim as Vector2 a, b, c, pixels(any)
    dim as Vector3 clipped(any), vertexes(any)
    dim as Vector3 normal, position
    dim as integer style = &hffff

    if wireColor <> 0 or vertexColor <> 0 then

        redim vertexes(ubound(face.vertexes))
        for i as integer = 0 to ubound(face.vertexes)
            vertexes(i) = worldToView(face.vertexes(i), camera)
        next i
        
        clipViewPoly3NearZ vertexes(), clipped(), camera
        
        if ubound(clipped) >= 2 then
            if doubleSided or normalColor <> 0 then
                normal = normalize(worldToView(face.normal, camera, true))
                position = worldToView(face.position, camera)
                style = iif(dot(normal, position) < 0, &hffff, &hf0f0)
            end if
            redim pixels(ubound(vertexes))
            for i as integer = 0 to ubound(vertexes)
                pixels(i) = viewToScreen(vertexes(i))
                pixels(i).x = pmap(pixels(i).x, 0)
                pixels(i).y = pmap(pixels(i).y, 1)
            next i
            ScreenMode.resetView()
            Rasterizer.drawWireframePoly pixels(), wireColor, style
            ScreenMode.applyView()
        end if
    end if
    'if normalColor then
    '    if position.z > 1 and position.z + normal.z > 1 then
    '        a = viewToScreen(position)
    '        b = viewToScreen(position + normal)
    '        line(a.x, a.y)-(b.x, b.y), normalColor, , style
    '    end if
    'end if
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
sub mergeSort(keys() as integer, vals() as double)

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
    if ubound(v0) > lbound(v0) or ubound(v1) > lbound(v1) then
        mergeSort k0(), v0()
        mergeSort k1(), v1()
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
    
    for i as integer = lbound(vals) to ubound(vals)
        vals(i) = vSorted(i)
        keys(i) = kSorted(i)
    next i
end sub
sub renderFaces(byref mesh as Mesh3, byref camera as CFrame3, byref world as CFrame3, renderMode as integer, textureMode as integer = -1)

    dim as Face3 face, sorted(any)
    dim as Vector3 normal, vertex
    dim as double vals(any)
    dim as integer keys(any)

    if renderMode = RenderModes.Wireframe then
        for i as integer = 0 to ubound(mesh.faces)
            renderFaceWireframe mesh.faces(i), camera, world, &hb0b0b0, mesh.doubleSided
        next i
        exit sub
    end if

    for i as integer = 0 to ubound(mesh.faces)
        face = mesh.faces(i)
        if not mesh.doubleSided then
            normal = normalize(worldToView(face.normal, camera, true))
            if dot(normal, vertex) > 0 then
                continue for
            end if
        end if
        vertex = worldToView(face.position + face.normal, camera)
        'if vertex.z <= 0 then
        '    continue for
        'end if
        array_append(keys, i)
        array_append(vals, vertex.length)
    next i

    mergeSort keys(), vals()
    foreach(keys, i as integer)
        array_append(sorted, mesh.faces(keys(i)))
    endforeach

    select case renderMode
    case RenderModes.Solid
        for i as integer = lbound(keys) to ubound(sorted)
            renderFaceSolid sorted(i), camera, world
        next i
    case RenderModes.Textured
        for i as integer = lbound(keys) to ubound(sorted)
            renderFaceTextured sorted(i), camera, world, mesh.textures(), textureMode
        next i
    case RenderModes.TexturedPC
        for i as integer = lbound(keys) to ubound(sorted)
            renderFaceTexturedPC sorted(i), camera, world, mesh.textures(), textureMode
        next i
    end select
end sub
sub renderBspFaces(node as BspNode3 ptr, faces() as Face3, byref mesh as Mesh3, byref camera as CFrame3, byref world as CFrame3, renderMode as integer, textureMode as integer = -1)
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
            renderBspFaces node->behind, faces(), mesh, camera, world, renderMode, textureMode
            renderBspFaces node->infront, faces(), mesh, camera, world, renderMode, textureMode
        else
            renderBspFaces node->infront, faces(), mesh, camera, world, renderMode, textureMode
            renderBspFaces node->behind, faces(), mesh, camera, world, renderMode, textureMode
        end if
        select case renderMode
            case RenderModes.Solid   : renderFaceSolid face, camera, world
            case RenderModes.Textured
                if ubound(face.uvs) >= 0 and ubound(mesh.textures) > -1 then
                    renderFaceTextured face, camera, world, mesh.textures(), textureMode
                else
                    renderFaceSolid face, camera, world
                end if
            case RenderModes.TexturedPC
                if ubound(face.uvs) >= 0 and ubound(mesh.textures) > -1 then
                    renderFaceTexturedPC face, camera, world, mesh.textures(), textureMode
                else
                    renderFaceSolid face, camera, world
                end if
            case RenderModes.Wireframe
                if dt > 0 then
                    'renderFaceWireframe face, camera, world
                else
                    'renderFaceWireframe face, camera, world
                end if
        end select
    end if
end sub
sub renderObjects(objects() as Object3 ptr, byref camera as CFrame3, byref world as CFrame3, renderMode as integer, textureMdoe as integer = -1)
    dim as Mesh3 mesh
    dim as integer keys(any)
    dim as double vals(any)
    for i as integer = 0 to ubound(objects)
        if objects(i)->visible then
            array_append(keys, i)
            array_append(vals, objects(i)->position = camera.position)
        end if
    next i
    for i as integer = 0 to ubound(objects)
        mesh = objects(i)->meshToWorld()
        renderFaces mesh, camera, world, renderMode, textureMdoe
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
        'o.cframe.position += normalize(cf.rightward - cf.upward) * deltaTime * 5
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
    while not game.keyDown(SC_ESCAPE)

        game.updateEvents()
        
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

        static as integer firstTime = 0
        '- docking station
        if firstTime then
            firstTime = 0
            dim as Face3 face
            face.normal   = type(0,0,1).normalized()
            face.position = type(1,0,0)
            'activeObject->mesh = (activeObject->mesh->splitMesh(face.normal, face.position))
            ' destroy old mesh (mainly texture memory)
        end if
        
        screencopy 1, 0

        deltaTime      = timer - frameStartTime
        frameStartTime = timer

        game.deltaTime = deltaTime
        game.mouse.update

        if game.keyPress(SC_F1) then setDebugLevel(1, game)
        if game.keyPress(SC_F2) then setDebugLevel(2, game)
        if game.keyPress(SC_F3) then setDebugLevel(3, game)
        if game.keyPress(SC_F4) then setDebugLevel(4, game)
        if game.keyPress(SC_F5) then
            if game.renderMode = RenderModes.Textured then
                game.renderMode = RenderModes.TexturedPC
            else
                game.renderMode = RenderModes.Textured
            end if
        end if

        if game.keyPress(SC_SLASH ) then textureMode = TextureModes.Auto
        if game.keyPress(SC_COMMA ) then textureMode -= iif(textureMode > TextureModes.Best , 1, 0)
        if game.keyPress(SC_PERIOD) then textureMode += iif(textureMode < TextureModes.Worst, 1, 0)

        if game.keyPress(SC_LEFTBRACKET ) then textureMode -= iif(textureMode > TextureModes.Best , 1, 0)
        if game.keyPress(SC_RIGHTBRACKET) then textureMode += iif(textureMode < TextureModes.Worst, 1, 0)

        if game.keyPress(SC_O) then activeObject->cframe = CFrame3()
        if game.keyPress(SC_X) then activeObject->cframe.orientation = Orientation3(Vector3(pi/2, 0, 0))
        if game.keyPress(SC_Y) then activeObject->cframe.orientation = Orientation3(Vector3(0, pi/2, 0))
        if game.keyPress(SC_Z) then activeObject->cframe.orientation = Orientation3(Vector3(0, 0, pi/2))

        if game.keyPress(SC_1) then navMode = NavigationModes.Fly   : game.activeObject = anchor   : setFlag(game.flags, GameFlags.ResetMode)
        if game.keyPress(SC_2) then navMode = NavigationModes.Follow: game.activeObject = spaceship: setFlag(game.flags, GameFlags.ResetMode)
        if game.keyPress(SC_3) then navMode = NavigationModes.Orbit : game.activeObject = spaceship: setFlag(game.flags, GameFlags.ResetMode)

        if game.keyPress(SC_CONTROL) or game.mouse.middleDown then
            game.camera.lookAt(spaceship->position, spaceship->upward)
        end if
    wend
end sub

sub renderFrame(byref game as GameSession)
    dim as CFrame3 cam = game.camera
    if game.keyDown(SC_BACKSPACE) then cam.orientation = cam.orientation.rotated(Vector3(0, rad(180), 0))
    line (ScreenMode.viewlft, ScreenMode.viewtop)-(ScreenMode.viewrgt, ScreenMode.viewbtm), game.bgColor, bf
    renderParticles(game.particles(), cam)
    renderObjects(game.objects(), cam, game.world, game.renderMode, game.textureMode)
end sub

sub renderRadar(byref game as GameSession)

    static as boolean drawRadar = true

    dim as Object3 ptr o, active = game.activeObject
    dim as Vector3 v

    if game.keyPress(SC_M) then drawRadar = not drawRadar
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
            if o->visible then
                v = o->position
                v = active->vectorToLocal(v)
                v /= 10
                circle (v.x, v.z + v.y), 3, &hffffff
            end if
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
    drawMouseCursor game
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
    if debugObject <> 0 and debugObject->mesh <> 0 then
        for i as integer = 0 to ubound(debugObject->mesh->faces)
            face = debugObject->mesh->faces(i)
            face.normal = debugObject->vectorToWorld(face.normal)
            face.position = debugObject->pointToWorld(face.position)
            'renderFaceWireframe face, game.camera, game.world, 0, , &hd00000
        next i
    end if
end sub

sub drawVertexes(byref game as GameSession)
    dim as Object3 ptr debugObject = game.debugObject
    dim as Face3 face
    dim as Vector3 vertex
    if debugObject <> 0 and debugObject->mesh <> 0 then
        for i as integer = 0 to ubound(debugObject->mesh->faces)
            face = debugObject->mesh->faces(i)
            for j as integer = 0 to ubound(face.vertexes)
                face.vertexes(j) = debugObject->pointToWorld(face.vertexes(j))
            next j
            'renderFaceWireframe face, game.camera, game.world, 0, &h00d000
        next i
    end if
end sub

sub drawMouseCursor(byref game as GameSession)
    dim byref as Mouse2 mouse = game.mouse
    dim as Vector2 a, b, m = type(mouse.x, mouse.y)
    dim as ulong ants = &hf0f0f0f0 shr int(frac(timer*1.5)*16)
    a = m
    b = Vector2(rad(-75))*0.076
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
        case RenderModes.Solid     : mid(buffer, 2) = "Solid"
        case RenderModes.Textured  : mid(buffer, 2) = "Texture"
        case RenderModes.TexturedPC: mid(buffer, 2) = "Texture Persp Corr"
        case RenderModes.Wireframe : mid(buffer, 2) = "Wireframe"
    end select
    printStringBlock(row, 1, buffer, "RENDER MODE", "_", "")

    if game.renderMode = RenderModes.Textured _
    or game.renderMode = RenderModes.TexturedPC then
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

    if game.keyDown(SC_W     ) then linearGoal.z =  1
    if game.keyDown(SC_S     ) then linearGoal.z = -1
    if game.keyDown(SC_D     ) then linearGoal.x =  1
    if game.keyDown(SC_A     ) then linearGoal.x = -1
    if game.keyDown(SC_SPACE ) then linearGoal.y =  1
    if game.keyDown(SC_LSHIFT) then linearGoal.y = -1
    

    if game.keyDown(SC_UP   ) then angularGoal.x = -1
    if game.keyDown(SC_DOWN ) then angularGoal.x =  1
    if game.keyDown(SC_RIGHT) then angularGoal.y =  1
    if game.keyDown(SC_LEFT ) then angularGoal.y = -1
    if game.keyDown(SC_E    ) then angularGoal.z = -1
    if game.keyDown(SC_Q    ) then angularGoal.z =  1

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

    if game.keyPress(SC_TAB) then
        distanceId += 1
        if distanceId > ubound(distances) then
            distanceId = lbound(distances)
        end if
    end if

    if game.keyDown(SC_W     ) then thrustGoal.z =  100
    if game.keyDown(SC_S     ) then thrustGoal.z = -20
    if game.keyDown(SC_D     ) then thrustGoal.x =  10
    if game.keyDown(SC_A     ) then thrustGoal.x = -10
    if game.keyDown(SC_SPACE ) then thrustGoal.y =  10
    if game.keyDown(SC_LSHIFT) then thrustGoal.y = -10

    if game.keyDown(SC_UP   ) then angularGoal.x =  1
    if game.keyDown(SC_DOWN ) then angularGoal.x = -1
    if game.keyDown(SC_RIGHT) then angularGoal.y =  1
    if game.keyDown(SC_LEFT ) then angularGoal.y = -1
    if game.keyDown(SC_E    ) then angularGoal.z = -1
    if game.keyDown(SC_Q    ) then angularGoal.z =  1

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

    static as Vector3 angular, linear, offset, upward, zero = Vector3.Zero
    static as boolean firstTime = true

    dim byref as Mouse2 mouse   = game.mouse
    dim byref as CFrame3 camera = game.camera
    dim as Object3 ptr active   = game.activeObject
    dim as double deltaTime     = game.deltaTime
    dim as double distance
    static as double x, y

    if game.keyPress(SC_TAB) then
        active = game.nextObject(active)
        game.activeObject = active
        game.debugObject  = active
        firstTime = true
    end if
    
    if firstTime or hasFlag(game.flags, GameFlags.ResetMode) then
        firstTime = false
        active->angular = Vector3.Randomized()
        offset = Vector3.Randomized() * (15 + 30*rnd)
        camera.position = active->position + active->vectorToWorld(offset)
        upward = Vector3.Randomized()
    end if
    
    camera.lookAt(active->position, upward)

    distance = (active->position - camera.position).length
    if mouse.leftDown then
        if active->angular <> zero then angular = active->angular: active->angular = zero
        if active->linear  <> zero then linear  = active->linear : active->linear  = zero
        x = -mouse.dragX
        y = -mouse.dragY * ScreenMode.ratiow
        camera.position += (camera.rightward * x + camera.upward * y) * distance * deltaTime
        camera.position = active->position + normalize(camera.position - active->position) * distance
        camera.lookAt(active->position, upward)
    else
        if angular <> Vector3.Zero then active->angular = angular: angular = zero
        if linear  <> Vector3.Zero then active->linear  = linear : linear  = zero
        camera.position -= camera.rightward * deltaTime * distance / 3
    end if

    if mouse.wheelDelta then
        camera.position += camera.forward * mouse.wheelDelta * distance / 20
    end if
    
end sub
