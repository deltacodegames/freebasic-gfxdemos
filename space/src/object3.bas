' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "object3.bi"

#macro array_append(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
#endmacro

declare sub string_split(subject as string, delim as string, pieces() as string)
'==============================================================================
'= CONSTRUCTOR
'==============================================================================
constructor Object3
end constructor
constructor Object3(sid as string, filename as string = "")
    this.sid = sid
    if filename <> "" then
        this.loadFile(filename)
    end if
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
function Object3.loadFile(filename as string) as integer
    dim as Vector3 vertexCollection(any)
    dim as Vector3 normalCollection(any)
    dim as Vector2 uvCollection(any)
    dim as string datum, pieces(any), subpieces(any), s, p
    dim as integer f = freefile
    open filename for input as #f
        while not eof(f)
            line input #f, s
            string_split(s, " ", pieces())
            for i as integer = 0 to ubound(pieces)
                dim as string datum = pieces(i)
                select case datum
                    case "o"
                        mesh.sid = pieces(i + 1)
                        continue while
                    case "v"
                        array_append(vertexCollection, type(_
                            val(pieces(1)),_
                            val(pieces(2)),_
                           -val(pieces(3)) _
                        ))
                    case "vn"
                        array_append(normalCollection, type(_
                            val(pieces(1)),_
                            val(pieces(2)),_
                           -val(pieces(3)) _
                        ))
                    case "vt"
                        array_append(uvCollection, type(_
                            val(pieces(1)),_
                            val(pieces(2)) _
                        ))
                    case "f"
                        dim as integer normalId, uvId, vertexId
                        dim as Face3 face
                        for j as integer = 0 to ubound(pieces) - 1
                            normalId = -1
                            uvId     = -1
                            vertexId = -1
                            dim as string p = pieces(1 + j)
                            if instr(p, "/") then
                                string_split(p, "/", subpieces())
                                for k as integer = 0 to ubound(subpieces)
                                    if subpieces(k) <> "" then
                                        select case k
                                            case 0: vertexId = val(subpieces(k)) - 1
                                            case 1: uvId     = val(subpieces(k)) - 1
                                            case 2: normalId = val(subpieces(k)) - 1
                                        end select
                                    end if
                                next k
                            else
                                vertexId = val(pieces(1 + j)) - 1
                            end if
                            if vertexId > -1 then
                                face.addVertex(vertexCollection(vertexId))
                            end if
                            if uvId > -1 then
                                face.addUv(uvCollection(uvId))
                            end if
                            if normalId > -1 then
                                face.autoCalcNormal = false
                                face.normal = normalCollection(normalId)
                            end if
                            print
                        next j
                        mesh.addFace(face)
                    case else
                        continue while
                end select
            next i
        wend
    close #1
    mesh.buildBsp()
    return 0
end function
function Object3.toWorld() as Object3
    dim as Object3 o = this
    dim as Face3 face
    dim as Vector3 vertex
    for i as integer = 0 to ubound(mesh.faces)
        face = mesh.faces(i)
        o.mesh.faces(i).position += this.position
        o.mesh.faces(i).normal _
            = rightward * face.normal.x _
            + upward    * face.normal.y _
            + forward   * face.normal.z
        for j as integer = 0 to ubound(face.vertexes)
            vertex = face.vertexes(j)
            o.mesh.faces(i).vertexes(j) _
                = rightward * vertex.x _
                + upward    * vertex.y _
                + forward   * vertex.z _
                + this.position
        next j
    next i
    return o
end function
function Object3.vectorToLocal(w as Vector3) as Vector3
    return Vector3(_
        dot(rightward, w),_
        dot(upward   , w),_
        dot(forward  , w) _
    )
end function
function Object3.vectorToWorld(l as Vector3) as Vector3
    return rightward * l.x + upward * l.y + forward * l.z
end function

'==============================================================================
'= FUNCTION
'==============================================================================
private sub string_split(subject as string, delim as string, pieces() as string)
    dim as integer i, j, index = -1
    dim as string s
    i = 1
    while i > 0
        s = ""
        j = instr(i, subject, delim)
        if j then
            s = mid(subject, i, j-i)
            i = j+1
        else
            s = mid(subject, i)
            i = 0
        end if
        index += 1: redim preserve pieces(index)
        pieces(index) = s
    wend
end sub
