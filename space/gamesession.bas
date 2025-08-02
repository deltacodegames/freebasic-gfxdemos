' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "gamesession.bi"

destructor GameSession
    for i as integer = 0 to ubound(objects)
        delete objects(i)
    next i
    for i as integer = 0 to ubound(particles)
        delete particles(i)
    next i
    for i as integer = 0 to ubound(textures)
        imagedestroy textures(i)
    next i
    erase objects
end destructor
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
function GameSession.addTexture(w as integer, h as integer, filename as string = "") as any ptr
    dim as any ptr buffer = imagecreate(w, h)
    dim as integer ub = ubound(textures) + 1
    if buffer then
        redim preserve textures(ub)
        textures(ub) = buffer
        if filename <> "" then
            bload filename, buffer
        end if
    end if
    return buffer
end function
function GameSession.findObject(sid as string) as Object3 ptr
    for i as integer = 0 to ubound(objects)
        if objects(i)->sid = sid then
            return objects(i)
        end if
    next i
    return 0
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
