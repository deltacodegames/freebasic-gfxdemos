' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "object3.bi"

#macro array_append(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
#endmacro

'==============================================================================
'= CONSTRUCTOR
'==============================================================================
constructor Object3
end constructor
constructor Object3(sid as string, mesh as Mesh3 ptr = 0)
    this.sid = sid
    this.mesh = mesh
end constructor
'==============================================================================
'= PROPERTY
'==============================================================================
property Object3.position as Vector3
    return this.cframe.position
end property
property Object3.position(newPosition as Vector3)
    this.cframe.position = newPosition
end property
property Object3.orientation as Orientation3
    return this.cframe.orientation
end property
property Object3.orientation(newOrientation as Orientation3)
    this.cframe.orientation = newOrientation
end property
property Object3.forward as Vector3
    return this.cframe.forward
end property
property Object3.rightward as Vector3
    return this.cframe.rightward
end property
property Object3.upward as Vector3
    return this.cframe.upward
end property
'==============================================================================
'= METHOD
'==============================================================================
function Object3.pointToWorld(l as Vector3) as Vector3
    return vectorToWorld(l) + position
end function
function Object3.meshToWorld() as Mesh3
    dim as Face3 face
    dim as Mesh3 newMesh
    dim as Vector3 vertex
    if mesh then
        newMesh = *mesh
        for i as integer = 0 to ubound(mesh->faces)
            face = newMesh.faces(i)
            newMesh.faces(i).normal _
                = rightward * face.normal.x _
                + upward    * face.normal.y _
                + forward   * face.normal.z
            newMesh.faces(i).position _
                = rightward * face.position.x _
                + upward    * face.position.y _
                + forward   * face.position.z _
                + this.position
            for j as integer = 0 to ubound(face.vertexes)
                vertex = face.vertexes(j)
                newMesh.faces(i).vertexes(j) _
                    = rightward * vertex.x _
                    + upward    * vertex.y _
                    + forward   * vertex.z _
                    + this.position
            next j
        next i
    end if
    return newMesh
end function
function Object3.vectorToLocal(byval w as Vector3) as Vector3
    w -= position
    return Vector3(_
        dot(rightward, w),_
        dot(upward   , w),_
        dot(forward  , w) _
    )
end function
function Object3.vectorToWorld(l as Vector3) as Vector3
    return rightward * l.x + upward * l.y + forward * l.z
end function
