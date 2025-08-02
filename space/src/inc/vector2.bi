' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------

type Vector2
    x as double
    y as double
    declare static function Randomized() as Vector2
    declare static function Randomized(a as double, b as double) as Vector2
    declare static function Zero() as Vector2
    declare constructor()
    declare constructor(x as double, y as double)
    declare constructor(radians as double)
    declare function length() as double
    declare function lerped(goal as Vector2, a as double=0.5) as Vector2
    declare function normalized() as Vector2
    declare function rotated(radians as double) as Vector2
    declare function rotatedLeft() as Vector2
    declare function rotatedRight() as Vector2
end type

declare operator int (a as Vector2) as Vector2
declare operator = (a as Vector2, b as Vector2) as boolean
declare operator <> (a as Vector2, b as Vector2) as boolean
declare operator - (a as Vector2) as Vector2
declare operator + (a as Vector2, b as Vector2) as Vector2
declare operator - (a as Vector2, b as Vector2) as Vector2
declare operator * (a as Vector2, b as Vector2) as Vector2
declare operator * (a as Vector2, b as double) as Vector2
declare operator / (a as Vector2, b as Vector2) as Vector2
declare operator / (a as Vector2, b as double) as Vector2
declare operator \ (a as Vector2, b as Vector2) as Vector2
declare operator \ (a as Vector2, b as double) as Vector2
declare operator ^ (a as Vector2, e as double) as Vector2

declare function cross overload(a as Vector2, b as Vector2) as double
declare function dot overload(a as Vector2, b as Vector2) as double
declare function dot overload(a() as Vector2, b as Vector2) as Vector2
declare function dot overload(a() as Vector2, b() as Vector2) as Vector2
declare function lerp overload(from as Vector2, goal as Vector2, a as double = 0.5) as Vector2
declare function magnitude overload(a as Vector2) as double
declare function normalize overload(a as Vector2) as Vector2
declare function rotate overload(a as Vector2, radians as double) as Vector2
declare function rotate_left overload(a as Vector2) as Vector2
declare function rotate_right overload(a as Vector2) as Vector2
