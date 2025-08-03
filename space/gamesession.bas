' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "gamesession.bi"
#include once "image32.bi"

#define rgb_r(c) (c shr 16 and &hff)
#define rgb_g(c) (c shr  8 and &hff)
#define rgb_b(c) (c        and &hff)

function lerpColor (from as long, goal as long, ratio as double = 0.5) as ulong
    dim as ubyte r, g, b
    ratio = iif(ratio < 0, ratio, iif(ratio > 1, 1, ratio))
    r = rgb_r(from) + int((rgb_r(goal) - rgb_r(from)) * ratio)
    g = rgb_g(from) + int((rgb_g(goal) - rgb_g(from)) * ratio)
    b = rgb_b(from) + int((rgb_b(goal) - rgb_b(from)) * ratio)
    return rgb(r, g, b)
end function

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

function GameSession.addObject(sid as string, filename as string = "") as Object3 ptr
    dim as integer ub = ubound(objects) + 1
    redim preserve objects(ub)
    objects(ub) = new Object3(sid, filename)
    return objects(ub)
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
function GameSession.generateShades(textureIndex as integer) as GameSession
    dim as any ptr texture
    dim as Image32 src, dest
    dim as double ratio
    dim as integer median
    dim as ulong colr

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
                        if shadeIndex <= median then
                            ratio = (median - shadeIndex) / median
                            colr = incrementColor(colr, -80 * ratio)
                        else
                            ratio = (shadeIndex - median) / (median + 1)
                            colr = incrementColor(colr,  80 * ratio)
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
