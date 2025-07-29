' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "face3.bi"
#include once "vector2.bi"
#include once "vector3.bi"
#include once "bspnode.bi"

type Mesh3
    bspRoot as BspNode3 ptr
    doubleSided as boolean = false
    faces(any) as Face3
    sid as string
    declare function addFace(face as Face3) as Mesh3
    declare function buildBsp() as Mesh3
    declare function centerGeometry() as Mesh3
    declare function generateBsp() as Mesh3
    declare function getFace(faceId as integer) as Face3
    declare function paintFaces(colr as integer) as Mesh3
    declare function textureFaces(texture as any ptr) as Mesh3
    declare function splitBsp(faceIds() as integer) as BspNode3 ptr
end type
