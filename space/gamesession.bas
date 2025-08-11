' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "gamesession.bi"
#include once "image32.bi"
#include once "fbgfx.bi"
using fb

#define rgb_r(c) (c shr 16 and &hff)
#define rgb_g(c) (c shr  8 and &hff)
#define rgb_b(c) (c        and &hff)

#macro array_append(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
#endmacro

declare function incrementColor (colr as ulong, inc as long) as ulong
declare function lerpColor (from as long, goal as long, ratio as double = 0.5) as ulong
declare function scaleColor (colr as long, factor as double) as ulong
declare sub      string_split(subject as string, delim as string, pieces() as string)
'==============================================================================
'= CONSTRUCTOR
'==============================================================================
'==============================================================================
'= METHOD
'==============================================================================
function GameSession.addObject(sid as string, mesh as Mesh3 ptr = 0) as Object3 ptr
    dim as integer ub = ubound(objects) + 1
    redim preserve objects(ub)
    objects(ub) = new Object3(sid, mesh)
    return objects(ub)
end function
function GameSession.addMesh(sid as string = "") as Mesh3 ptr
    dim as integer ub = ubound(meshes) + 1
    redim preserve meshes(ub)
    meshes(ub) = new Mesh3(sid)
    return meshes(ub)
end function
function GameSession.addParticle(position as Vector3, colr as integer) as Particle3 ptr
    dim as integer ub = ubound(particles) + 1
    redim preserve particles(ub)
    particles(ub) = new Particle3(position, colr)
    return particles(ub)
end function
function GameSession.addTexture(w as integer, h as integer, filename as string = "") as integer
    dim as integer index
    dim as any ptr buffer = imagecreate(w, h)
    if buffer then
        if filename <> "" then
            bload filename, buffer
        end if
        index = ubound(textures) + 1
        redim preserve textures(index)
        textures(index) = buffer
        return index
    else
        return -1
    end if
end function
function GameSession.free() as GameSession
    for i as integer = 0 to ubound(objects)
        delete objects(i)
        objects(i) = 0
    next i
    for i as integer = 0 to ubound(meshes)
        delete meshes(i)
        meshes(i) = 0
    next i
    for i as integer = 0 to ubound(particles)
        delete particles(i)
        particles(i) = 0
    next i
    for i as integer = 0 to ubound(shades, 1)
        for j as integer = 0 to ubound(shades, 2)
            if shades(i, j) then
                imagedestroy shades(i, j)
            end if
            shades(i, j) = 0
        next j
    next i
    for i as integer = 0 to ubound(textures)
        if textures(i) then
            imagedestroy textures(i)
        end if
        textures(i) = 0
    next i
    erase objects
    erase particles
    erase shades
    erase textures
    return this
end function
function GameSession.generateShades(textureIndex as integer, darkest as double = 0.5, brightest as double = 1.5) as GameSession
    dim as any ptr texture
    dim as Image32 src, dest
    dim as double ratio
    dim as integer median
    dim as ulong colr, from, goal

    texture = getTexture(textureIndex)
    if texture then
        if ubound(shades, 1) < textureIndex then
            redim preserve shades(textureIndex, GeneratedShadesCount-1)
        end if
        median = ubound(shades, 2) \ 2
        for shadeIndex as integer = 0 to ubound(shades, 2)
            src.readInfo(texture)
            dest.readInfo(imagecreate(src.w, src.h))
            if dest.buffer then
                shades(textureIndex, shadeIndex) = dest.buffer
                for y as integer = 0 to src.h-1
                    for x as integer = 0 to src.w-1
                        colr = src.getPixel(x, y)
                        ratio = shadeIndex / ubound(shades, 2)
                        if ratio < 0.5 then
                            ratio = 2*ratio
                            from  = colr
                            goal  = scaleColor(colr, darkest)
                            colr  = lerpColor(from, goal, 1-ratio)
                        else
                            ratio = 2*(ratio-0.5)
                            from  = colr
                            goal  = scaleColor(colr, brightest)
                            colr  = lerpColor(from, goal, ratio)
                        end if
                        dest.putPixel x, y, colr
                    next x
                next y
            end if
        next shadeIndex
    end if
    return this
end function
function GameSession.findObject(sid as string) as Object3 ptr
    for i as integer = 0 to ubound(objects)
        if objects(i)->sid = sid then
            return objects(i)
        end if
    next i
    return 0
end function
function GameSession.getShade(textureIndex as integer, shadeIndex as integer = -1) as any ptr
    if textureIndex > -1 and textureIndex <= ubound(shades, 1) then
        if shadeIndex > -1 and shadeIndex <= ubound(shades, 2) then
            return shades(textureIndex, shadeIndex)
        end if
    else
        return 0
    end if
end function
function GameSession.getTexture(index as integer) as any ptr
    if index > -1 and index <= ubound(textures) then
        return textures(index)
    else
        return 0
    end if
end function
function GameSession.keyDown(scancode as integer) as boolean
    return (keys(scancode) = 1) or (keys(scancode) = 2)
end function
function GameSession.keyPress(scancode as integer) as boolean
    return (keys(scancode) = 1)
end function
function GameSession.keyRepeat(scancode as integer) as boolean
    return (keys(scancode) = 2)
end function
function GameSession.keyUp(scancode as integer) as boolean
    return (keys(scancode) = 3)
end function
function GameSession.loadMesh(filename as string, mesh as Mesh3 ptr = 0) as Mesh3 ptr
    dim as Vector3 vertexCollection(any)
    dim as Vector3 normalCollection(any)
    dim as Vector2 uvCollection(any)
    dim as string datum, pieces(any), subpieces(any), s, p
    if mesh = 0 then
        mesh = this.addMesh()
    end if
    dim as integer f = freefile
    open filename for input as #f
        while not eof(f)
            line input #f, s
            string_split(s, " ", pieces())
            for i as integer = 0 to ubound(pieces)
                dim as string datum = pieces(i)
                select case datum
                    case "o"
                        mesh->sid = pieces(i + 1)
                        continue while
                    case "v"
                        array_append(vertexCollection, type(_
                            val(pieces(1)),_
                            val(pieces(2)),_
                           -val(pieces(3)) _
                        ))
                        mesh->addVertex(type(_
                            val(pieces(1)),_
                            val(pieces(2)),_
                           -val(pieces(3)) _
                        ))
                    case "vn"
                        array_append(normalCollection, type(_
                            val(pieces(1)),_
                            val(pieces(2)),_
                           -val(pieces(3)) _
                        ))
                    case "vt"
                        array_append(uvCollection, type(_
                            val(pieces(1)),_
                            1-val(pieces(2)) _
                        ))
                    case "f"
                        dim as integer normalId, uvId, vertexId
                        dim as Face3 face
                        for j as integer = 0 to ubound(pieces) - 1
                            normalId = -1
                            uvId     = -1
                            vertexId = -1
                            dim as string p = pieces(1 + j)
                            if instr(p, "/") then
                                string_split(p, "/", subpieces())
                                for k as integer = 0 to ubound(subpieces)
                                    if subpieces(k) <> "" then
                                        select case k
                                            case 0: vertexId = val(subpieces(k)) - 1
                                            case 1: uvId     = val(subpieces(k)) - 1
                                            case 2: normalId = val(subpieces(k)) - 1
                                        end select
                                    end if
                                next k
                            else
                                vertexId = val(pieces(1 + j)) - 1
                            end if
                            if vertexId > -1 then
                                face.addVertex(vertexCollection(vertexId))
                            end if
                            if uvId > -1 then
                                face.addUv(uvCollection(uvId))
                            end if
                            if normalId > -1 then
                                face.normal = normalCollection(normalId)
                            end if
                            print
                        next j
                        mesh->addFace(face)
                    case else
                        continue while
                end select
            next i
        wend
    close #1
    'mesh.buildBsp()
    return mesh
end function
function GameSession.nextObject(fromObject as Object3 ptr) as Object3 ptr
    for i as integer = 0 to ubound(objects)
        if objects(i) = fromObject then
            for j as integer = i+1 to ubound(objects)
                if objects(j)->visible then
                    return objects(j)
                end if
            next j
            for j as integer = 0 to i-1
                if objects(j)->visible then
                    return objects(j)
                end if
            next j
        end if
    next i
    return fromObject
end function
function GameSession.updateEvents() as GameSession
    dim as Event e
    for i as integer = 0 to ubound(keys)
        if keys(i) = 1 then
            keys(i) = 2
        elseif keys(i) = 3 then
            keys(i) = 0
        end if
    next i
    while screenevent(@e)
        select case e.type
        case EVENT_KEY_PRESS
            if e.scancode <= ubound(keys) then
                keys(e.scancode) = 1
            end if
        case EVENT_KEY_RELEASE
            if e.scancode <= ubound(keys) then
                keys(e.scancode) = 3
            end if
        case EVENT_KEY_REPEAT
            if e.scancode <= ubound(keys) then
                keys(e.scancode) = 2
            end if
        end select
    wend
    return this
end function

'==============================================================================
'= PRIVATE
'==============================================================================
function incrementColor (colr as ulong, inc as long) as ulong
    dim as long r, g, b
    r = rgb_r(colr) + inc
    g = rgb_g(colr) + inc
    b = rgb_b(colr) + inc
    r = iif(r < 0, 0, iif(r > 255, 255, r))
    g = iif(g < 0, 0, iif(g > 255, 255, g))
    b = iif(b < 0, 0, iif(b > 255, 255, b))
    return rgb(r, g, b)
end function

function lerpColor (from as long, goal as long, ratio as double = 0.5) as ulong
    dim as ubyte r, g, b
    ratio = iif(ratio < 0, 0, iif(ratio > 1, 1, ratio))
    r = rgb_r(from) + int((rgb_r(goal) - rgb_r(from)) * ratio)
    g = rgb_g(from) + int((rgb_g(goal) - rgb_g(from)) * ratio)
    b = rgb_b(from) + int((rgb_b(goal) - rgb_b(from)) * ratio)
    return rgb(r, g, b)
end function

function scaleColor (colr as long, factor as double) as ulong
    dim as long r, g, b
    r = int(rgb_r(colr) * factor)
    g = int(rgb_g(colr) * factor)
    b = int(rgb_b(colr) * factor)
    r = iif(r < 0, 0, iif(r > 255, 255, r))
    g = iif(g < 0, 0, iif(g > 255, 255, g))
    b = iif(b < 0, 0, iif(b > 255, 255, b))
    return rgb(r, g, b)
end function

private sub string_split(subject as string, delim as string, pieces() as string)
    dim as integer i, j, index = -1
    dim as string s
    i = 1
    while i > 0
        s = ""
        j = instr(i, subject, delim)
        if j then
            s = mid(subject, i, j-i)
            i = j+1
        else
            s = mid(subject, i)
            i = 0
        end if
        index += 1: redim preserve pieces(index)
        pieces(index) = s
    wend
end sub
