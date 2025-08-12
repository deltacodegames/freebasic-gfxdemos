' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "vector2.bi"
#include once "vector3.bi"

type Face3
    id as ushort
    colr as integer = rgb(128+92*rnd, 128+92*rnd, 128+92*rnd)
    position as Vector3
    normal as Vector3
    uvs(any) as Vector2
    vertexes(any) as Vector3
    uvIds(any) as ushort
    vertexIds(any) as ushort
    declare function addUv(uv as Vector2) as Face3
    declare function addUvId(uvId as ushort) as Face3
    declare function addVertex(vertex as Vector3) as Face3
    declare function addVertexId(vertexId as ushort) as Face3
    declare function calcNormal() as Face3
    declare function calcPosition() as Face3
end type
