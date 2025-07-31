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
    faces(any) as Face3
    sid as string
    declare function addFace(face as Face3) as Mesh3
    declare function buildBsp() as Mesh3
    declare function buildBsp(collection() as Face3) as BspNode3 ptr
    declare function centerGeometry() as Mesh3
    declare function deleteFaces() as Mesh3
    declare function generateBsp() as Mesh3
    declare function getFaceById(id as integer) as Face3
    declare function paintFaces(colr as integer) as Mesh3
    declare function setFacesDoubleSided(doubleSided as boolean) as Mesh3
    declare function splitMesh(splitterNormal as Vector3, splitterPosition as Vector3) as Mesh3
    declare function textureFaces(texture as any ptr) as Mesh3
end type
