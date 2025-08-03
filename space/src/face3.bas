' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "face3.bi"

#macro array_append(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
#endmacro

function Face3.addUv(uv as Vector2) as Face3
    array_append(uvs, uv)
    return this
end function
function Face3.addVertex(vertex as Vector3) as Face3
    array_append(vertexes, vertex)
    calcPosition()
    return this
end function
function Face3.calcNormal() as Face3
    dim as Vector3 a, b, c, norm
    dim as integer ub, vertexCount
    ub = ubound(vertexes)
    vertexCount = ub + 1
    if vertexCount = 3 then
        a = vertexes(0)
        b = vertexes(1)
        c = vertexes(2)
        norm = cross(b-a, c-a)
    elseif vertexCount > 3 then
        for i as integer = 1 to ub - 1
            a = vertexes(0)
            b = vertexes(i)
            c = vertexes(i+1)
            norm += cross(b-a, c-a)
        next i
    end if
    this.normal = normalize(norm)
    return this
end function
function Face3.calcPosition() as Face3
    dim as Vector3 vertexSum
    if ubound(vertexes) >= 0 then
        for i as integer = 0 to ubound(vertexes)
            vertexSum += vertexes(i)
        next i
        position = vertexSum / (ubound(vertexes) + 1)
    end if
    return this
end function
