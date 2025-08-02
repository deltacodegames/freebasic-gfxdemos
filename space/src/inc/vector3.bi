' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------

enum Axis3
    X = 0
    Y = 1
    Z = 2
end enum

type Vector3
    x as double
    y as double
    z as double
    declare static function Randomized() as Vector3
    declare static function Randomized(a as double, b as double, c as double) as Vector3
    declare static function Zero() as Vector3
    declare constructor()
    declare constructor(x as double, y as double, z as double)
    declare function length() as double
    declare function lerped(goal as Vector3, a as double=0.5) as Vector3
    declare function normalized() as Vector3
    declare function rotated(radians as double, axis as integer = 2) as Vector3
end type

declare operator int (a as Vector3) as Vector3
declare operator = (a as Vector3, b as Vector3) as boolean
declare operator <> (a as Vector3, b as Vector3) as boolean
declare operator - (a as Vector3) as Vector3
declare operator + (a as Vector3, b as Vector3) as Vector3
declare operator - (a as Vector3, b as Vector3) as Vector3
declare operator * (a as Vector3, b as Vector3) as Vector3
declare operator * (a as Vector3, b as double) as Vector3
declare operator / (a as Vector3, b as Vector3) as Vector3
declare operator / (a as Vector3, b as double) as Vector3
declare operator \ (a as Vector3, b as Vector3) as Vector3
declare operator \ (a as Vector3, b as double) as Vector3
declare operator ^ (a as Vector3, e as double) as Vector3

declare function cross     overload(a as Vector3, b as Vector3) as Vector3
declare function dot       overload(a as Vector3, b as Vector3) as double
declare function dot       overload(a() as Vector3, b as Vector3) as Vector3
declare function dot       overload(a() as Vector3, b() as Vector3) as Vector3
declare function lerp      overload(from as Vector3, goal as Vector3, a as double = 0.5) as Vector3
declare function magnitude overload(a as Vector3) as double
declare function normalize overload(a as Vector3) as Vector3
declare function rotate    overload(a as Vector3, radians as double, axis as integer = 2) as Vector3
