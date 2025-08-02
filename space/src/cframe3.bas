' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "cframe3.bi"

'==============================================================================
'= CONSTRUCTOR
'==============================================================================
constructor CFrame3
end constructor
constructor CFrame3(position as Vector3)
    this.position = position
end constructor
constructor CFrame3(orientation as Orientation3)
    this.orientation = orientation
end constructor
constructor CFrame3(position as Vector3, orientation as Orientation3)
    this.position    = position
    this.orientation = orientation
end constructor
constructor CFrame3(position as Vector3, axisRotations as Vector3)
    this.position    = position
    this.orientation = Orientation3(axisRotations)
end constructor
'==============================================================================
'= OPERATOR
'==============================================================================
operator + (a as CFrame3, b as CFrame3) as CFrame3
    return CFrame3(a.position + b.position, a.orientation)
end operator
operator + (a as CFrame3, b as Vector3) as CFrame3
    return CFrame3(a.position + b, a.orientation)
end operator
operator - (a as CFrame3, b as CFrame3) as CFrame3
    return CFrame3(a.position - b.position, a.orientation)
end operator
operator - (a as CFrame3, b as Vector3) as CFrame3
    return a + -b
end operator
operator * (a as CFrame3, b as CFrame3) as CFrame3
    return CFrame3(a.position + b.position, a.orientation * b.orientation)
end operator
operator * (a as CFrame3, b as Orientation3) as CFrame3
    return CFrame3(a.position, a.orientation * b)
end operator
'==============================================================================
'= PROPERTY
'==============================================================================
property CFrame3.forward   as Vector3: return this.orientation.forward  : end property
property CFrame3.rightward as Vector3: return this.orientation.rightward: end property
property CFrame3.upward    as Vector3: return this.orientation.upward   : end property
'==============================================================================
'= FUNCTION
'==============================================================================
function lerp overload(from as CFrame3, goal as CFrame3, a as double = 0.5) as CFrame3
    return type(_
        lerp(from.position, goal.position, a),_
        lerp(from.orientation, goal.orientation, a) _
    )
end function
'==============================================================================
'= METHOD
'==============================================================================
function CFrame3.lerped(goal as CFrame3, a as double=0.5) as CFrame3
    return lerp(this, goal, a)
end function
function CFrame3.lookAt(target as Vector3, worldUp as Vector3 = type(0, 1, 0)) as CFrame3
    this.orientation = Orientation3.Look(target - position, worldUp)
    return this
end function
