' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "vector3.bi"

type Orientation3
    matrix(0 to 2) as Vector3 = _
    {_
        type(1,  0,  0),_
        type(0,  1,  0),_
        type(0,  0,  1) _
    }
    declare constructor ()
    declare constructor (o0 as Vector3, o1 as Vector3, o2 as Vector3)
    declare constructor (axisRotations as Vector3)
    declare property forward as Vector3
    declare property rightward as Vector3
    declare property upward as Vector3
    declare function lerped(goal as Orientation3, a as double=0.5) as Orientation3
    declare function rotated(axisRotations as Vector3) as Orientation3
    declare static function Look(forward as Vector3, worldUp as Vector3 = type(0, 1, 0)) as Orientation3
end type

declare operator * (a as Orientation3, b as Orientation3) as Orientation3
declare operator * (a as Orientation3, b as Vector3) as Vector3

declare function lerp overload(from as Orientation3, goal as Orientation3, a as double=0.5) as Orientation3
declare function rotate overload(a as Orientation3, axisRotations as Vector3) as Orientation3
