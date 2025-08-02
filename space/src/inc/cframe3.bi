' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "orientation3.bi"
#include once "vector3.bi"

type CFrame3
    position as Vector3
    orientation as Orientation3
    declare constructor ()
    declare constructor (position as Vector3)
    declare constructor (position as Vector3, orientation as Orientation3)
    declare constructor (orientation as Orientation3)
    declare constructor (position as Vector3, axisRotations as Vector3)
    declare property forward as Vector3
    declare property rightward as Vector3
    declare property upward as Vector3
    declare function lerped(goal as CFrame3, a as double=0.5) as CFrame3
    declare function lookAt(target as Vector3, worldUp as Vector3 = type(0, 1, 0)) as CFrame3
end type

declare operator + (a as CFrame3, b as CFrame3) as CFrame3
declare operator + (a as CFrame3, b as Vector3) as CFrame3
declare operator - (a as CFrame3, b as CFrame3) as CFrame3
declare operator - (a as CFrame3, b as Vector3) as CFrame3
declare operator * (a as CFrame3, b as CFrame3) as CFrame3
declare operator * (a as CFrame3, b as Orientation3) as CFrame3

declare function lerp overload(from as CFrame3, goal as CFrame3, a as double = 0.5) as CFrame3
