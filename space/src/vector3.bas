' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "vector3.bi"

constructor Vector3
end constructor
constructor Vector3(x as double, y as double, z as double)
    this.x = x
    this.y = y
    this.z = z
end constructor
operator int (a as Vector3) as Vector3
    return type(int(a.x), int(a.y), int(a.z))
end operator
operator = (a as Vector3, b as Vector3) as boolean
    return a.x=b.x and a.y=b.y and a.z=b.z
end operator
operator <> (a as Vector3, b as Vector3) as boolean
    return a.x<>b.x or a.y<>b.y or a.z<>b.z
end operator
operator - (a as Vector3) as Vector3
    return type(-a.x, -a.y, -a.z)
end operator
operator + (a as Vector3, b as Vector3) as Vector3
    return type(a.x+b.x, a.y+b.y, a.z+b.z)
end operator
operator - (a as Vector3, b as Vector3) as Vector3
    return a + -b
end operator
operator * (a as Vector3, b as Vector3) as Vector3
    return type(a.x*b.x, a.y*b.y, a.z*b.z)
end operator
operator * (a as Vector3, b as double) as Vector3
    return type(a.x*b, a.y*b, a.z*b)
end operator
operator / (a as Vector3, b as Vector3) as Vector3
    return type(a.x/b.x, a.y/b.y, a.z/b.z)
end operator
operator / (a as Vector3, b as double) as Vector3
    return type(a.x/b, a.y/b, a.z/b)
end operator
operator \ (a as Vector3, b as Vector3) as Vector3
    return int(a) / int(b)
end operator
operator \ (a as Vector3, b as double) as Vector3
    return int(a) / int(b)
end operator
operator ^ (a as Vector3, e as double) as Vector3
    return type(a.x^e, a.y^e, a.z^e)
end operator
function cross overload(a as Vector3, b as Vector3) as Vector3
    return type(_
        a.y*b.z - a.z*b.y,_
        a.z*b.x - a.x*b.z,_
        a.x*b.y - a.y*b.x _
    )
end function
function dot overload(a as Vector3, b as Vector3) as double
    return a.x*b.x + a.y*b.y + a.z*b.z
end function
function dot overload(a() as Vector3, b as Vector3) as Vector3
    return a(0)*b.x + a(1)*b.y + a(2)*b.z
end function
function dot overload(a() as Vector3, b() as Vector3) as Vector3
    return a(0)*b(0) + a(1)*b(1) + a(2)*b(2)
end function
function lerp overload(from as Vector3, goal as Vector3, a as double = 0.5) as Vector3
    a = iif(a < 0, 0, iif(a > 1, 1, a))
    return type(_
        from.x + (goal.x - from.x) * a,_
        from.y + (goal.y - from.y) * a,_
        from.z + (goal.z - from.z) * a _
    )
end function
function magnitude overload(a as Vector3) as double
    return sqr(a.x*a.x + a.y*a.y + a.z*a.z)
end function
function normalize overload(a as Vector3) as Vector3
    return a / magnitude(a)
end function
function rotate overload(a as Vector3, radians as double, axis as integer = 2) as Vector3
    dim v as Vector3
    dim as double rcos = cos(radians)
    dim as double rsin = sin(radians)
    select case axis
    case 0
        v.x = a.x
        v.y = a.y * rcos + a.z * -rsin
        v.z = a.y * rsin + a.z *  rcos
    case 1
        v.y = a.y
        v.z = a.z * rcos + a.x * -rsin
        v.x = a.z * rsin + a.x *  rcos
    case 2
        v.z = a.z
        v.x = a.x * rcos + a.y * -rsin
        v.y = a.x * rsin + a.y *  rcos
    end select
    return v
end function
function volume(a as Vector3, b as Vector3, c as Vector3) as double
    return dot(a, cross(b, c))
end function
function Vector3.length() as double
    return magnitude(this)
end function
function Vector3.lerped(goal as Vector3, a as double=0.5) as Vector3
    return lerp(this, goal, a)
end function
function Vector3.normalized() as Vector3
    return normalize(this)
end function
function Vector3.rotated(radians as double, axis as integer = 2) as Vector3
    return rotate(this, radians, axis)
end function
static function Vector3.Randomized() as Vector3
    return normalize(type(-.5+rnd,-.5+rnd,-.5+rnd))
end function
static function Vector3.Randomized(a as double, b as double, c as double) as Vector3
    dim as double sum = a + b + c
    return normalize(type(-.5+rnd,-.5+rnd,-.5+rnd) * type(a/sum, b/sum, c/sum))
end function
static function Vector3.Zero() as Vector3
    return type(0, 0, 0)
end function
