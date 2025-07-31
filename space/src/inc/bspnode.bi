' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "vector3.bi"

type BspNode3
    as integer faceId
    as Vector3 normal, position
    as BspNode3 ptr behind, infront
end type
