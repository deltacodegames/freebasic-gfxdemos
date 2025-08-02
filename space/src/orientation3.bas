' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "orientation3.bi"
#include once "vector2.bi"

'===============================================================================
'= CONSTRUCTOR
'===============================================================================
constructor Orientation3
end constructor
constructor Orientation3(o0 as Vector3, o1 as Vector3, o2 as Vector3)
    this.matrix(0) = o0
    this.matrix(1) = o1
    this.matrix(2) = o2
end constructor
constructor Orientation3(axisRotations as Vector3)
    this = rotate(this, axisRotations)
end constructor
'===============================================================================
'= OPERATOR
'===============================================================================
operator * (a as Orientation3, b as Orientation3) as Orientation3
    return Orientation3(_
        dot(a.matrix(), b.matrix(0)),_
        dot(a.matrix(), b.matrix(1)),_
        dot(a.matrix(), b.matrix(2)) _
    )
end operator
operator * (a as Orientation3, b as Vector3) as Vector3
    return dot(a.matrix(), b)
end operator
'===============================================================================
'= PROPERTY
'===============================================================================
property Orientation3.forward as Vector3  : return this.matrix(Axis3.Z): end property
property Orientation3.rightward as Vector3: return this.matrix(Axis3.X): end property
property Orientation3.upward as Vector3   : return this.matrix(Axis3.Y): end property
'===============================================================================
'= FUNCTION
'===============================================================================
function lerp overload(from as Orientation3, goal as Orientation3, a as double=0.5) as Orientation3
    return type(_
        lerp(from.matrix(0), goal.matrix(0), a),_
        lerp(from.matrix(1), goal.matrix(1), a),_
        lerp(from.matrix(2), goal.matrix(2), a) _
    )
end function
function rotate overload(a as Orientation3, axisRotations as Vector3) as Orientation3
    dim as Vector3 x, y, z
    dim as double radians
    for i as integer = 0 to 2
        select case i
            case Axis3.X: radians = axisRotations.x
            case Axis3.Y: radians = axisRotations.y
            case Axis3.Z: radians = axisRotations.z
        end select
        if radians then
            select case i
            case Axis3.X
                y = rotate(Vector3(0,1,0), radians, i)
                z = rotate(Vector3(0,0,1), radians, i)
                x = cross(y, z)
            case Axis3.Y
                z = rotate(Vector3(0,0,1), radians, i)
                x = rotate(Vector3(1,0,0), radians, i)
                y = cross(z, x)
            case Axis3.Z
                x = rotate(Vector3(1,0,0), radians, i)
                y = rotate(Vector3(0,1,0), radians, i)
                z = cross(x, y)
            end select
            a *= Orientation3(x, y, z)
        end if
    next i
    return a
end function
'===============================================================================
'= METHODS
'===============================================================================
function Orientation3.lerped(goal as Orientation3, a as double=0.5) as Orientation3
    return lerp(this, goal, a)
end function
function Orientation3.rotated(axisRotations as Vector3) as Orientation3
    return rotate(this, axisRotations)
end function
function Orientation3.Look(direction as Vector3, worldUp as Vector3 = type(0, 1, 0)) as Orientation3
    dim as Vector3 x, y, z
    z = normalize(direction)
    x = normalize(cross(z, worldUp))
    y = normalize(cross(z, x))
    return Orientation3(x, y, z)
end function
