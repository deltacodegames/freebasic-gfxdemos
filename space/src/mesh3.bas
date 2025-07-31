' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "mesh3.bi"
#include once "bspnode.bi"

#macro array_append(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
#endmacro

function Mesh3.addFace(face as Face3) as Mesh3
    array_append(faces, face)
    faces(ubound(faces)).id = ubound(faces)
    return this
end function
function Mesh3.buildBsp() as Mesh3
    dim as Face3 collection(any)
    for i as integer = 0 to ubound(faces)
        if ubound(faces(i).vertexes) >= 0 then
            array_append(collection, faces(i))
        end if
        bspRoot = buildBsp(collection())
    next i
    return this
end function
function Mesh3.buildBsp(collection() as Face3) as BspNode3 ptr
    dim as BspNode3 ptr node
    dim as Face3 backs(any), fronts(any)
    dim as Face3 face, behind, infront, splitter
    dim as Vector3 average, backSum, frontSum, rootSum
    dim as integer backIndex, frontIndex, splitterIndex

    if ubound(collection) = -1 then return 0

    for i as integer = 0 to ubound(collection)
        face = collection(i)
        rootSum += face.position
    next i
    average = rootSum / (ubound(collection) + 1)
    
    splitter = collection(0)
    for i as integer = 1 to ubound(collection)
        face = collection(i)
        if (face.position - average).length < (splitter.position - average).length then
            splitter = face
            splitterIndex = i
        end if
    next i

    node = new BspNode3
    for i as integer = 0 to ubound(faces)
        face = faces(i)
        if splitter.normal = face.normal and splitter.position = face.position then
            node->faceId = face.id
            exit for
        end if
    next i
    
    node->normal   = splitter.normal
    node->position = splitter.position
    'this = this.splitMesh(node->normal, node->position)
    for i as integer = 0 to ubound(collection)
        face = collection(i)
        if i <> splitterIndex then
            if dot(splitter.normal, face.position - splitter.position) <= 0 then
                array_append(backs, face)
                backSum += face.position
            else
                array_append(fronts, face)
                frontSum += face.position
            end if
        end if
    next i

    backIndex  = -1
    frontIndex = -1

    if ubound(backs) >= 0 then
        average   = backSum / (ubound(backs) + 1)
        behind    = backs(0)
        backIndex = 0
        for i as integer = 1 to ubound(backs)
            face = backs(i)
            if (face.position - average).length < (behind.position - average).length then
                backIndex = i
            end if
        next i
    end if
    if ubound(fronts) >= 0 then
        average    = frontSum / (ubound(fronts) + 1)
        infront    = fronts(0)
        frontIndex = 0
        for i as integer = 1 to ubound(fronts)
            face = fronts(i)
            if (face.position - average).length < (infront.position - average).length then
                frontIndex = i
            end if
        next i
    end if

    if backIndex >= 0 then
        node->behind  = buildBsp(backs())
    end if
    if frontIndex >= 0 then
        node->infront = buildBsp(fronts())
    end if
    
    return node
end function
function Mesh3.centerGeometry() as Mesh3
    dim as Vector3 average, unique(any), vertex
    dim as Face3 face
    dim as boolean isUnique
    for i as integer = 0 to ubound(faces)
        face = faces(i)
        for j as integer = 0 to ubound(face.vertexes)
            vertex = face.vertexes(j)
            isUnique = true
            for k as integer = 0 to ubound(unique)
                if vertex = unique(k) then
                    isUnique = false
                    exit for
                end if
            next k
            if isUnique then
                array_append(unique, vertex)
            end if
        next j
    next i
    if ubound(unique) >= 0 then
        for i as integer = 0 to ubound(unique)
            average += unique(i)
        next i
        average /= (ubound(unique) + 1)
        for i as integer = 0 to ubound(faces)
            for j as integer = 0 to ubound(face.vertexes)
                faces(i).vertexes(j) -= average
            next j
        next i
    end if
    return this
end function
function Mesh3.deleteFaces() as Mesh3
    erase faces
    return this
end function
function Mesh3.getFaceById(id as integer) as Face3
    return faces(id)
end function
function Mesh3.paintFaces(colr as integer) as Mesh3
    for i as integer = 0 to ubound(faces)
        faces(i).colr = colr
    next i
    return this
end function
function Mesh3.setFacesDoubleSided(doubleSided as boolean) as Mesh3
    for i as integer = 0 to ubound(faces)
        faces(i).doubleSided = doubleSided
    next i
    return this
end function
function Mesh3.splitMesh(splitterNormal as Vector3, splitterPosition as Vector3) as Mesh3

    dim as Mesh3 newMesh
    dim as Face3 face, newFace
    dim as Vector3 a, b, c, normal, vertex
    dim as double sidea, sideb
    
    newMesh = this
    newMesh.sid = this.sid + "." + str((999999999-100000000)*rnd)
    newMesh.deleteFaces()
    
    for i as integer = 0 to ubound(this.faces)
        face = this.faces(i)
        newFace = Face3()
        newFace.normal = face.normal
        for j as integer = 0 to 1
            normal = iif(j = 0, splitterNormal, -splitterNormal)
            for k as integer = 0 to ubound(face.vertexes)
                if k < ubound(face.vertexes) then
                    a = face.vertexes(k)
                    b = face.vertexes(k+1)
                else
                    a = face.vertexes(k)
                    b = face.vertexes(0)
                end if
                sidea = dot(normal, a - splitterPosition)
                sideb = dot(normal, b - splitterPosition)
                if sidea > 0 then
                    newFace.addVertex(a)
                    if sideb > 0 then
                        newFace.addVertex(b)
                    elseif sideb < 0 then
                        c = a + (b - a) * sidea / (sidea + abs(sideb))
                        newFace.addVertex(c)
                    end if
                elseif sideb > 0 then
                    'c = b + (a - b) * sideb / (sideb + abs(sidea))
                    'newFace.addVertex(c)
                    newFace.addVertex(b)
                end if
            next k
        next j
        if ubound(newFace.vertexes) >= 2 then
            newMesh.addFace(newFace)
        end if
    next i
    return newMesh.buildBsp()
end function
function Mesh3.textureFaces(texture as any ptr) as Mesh3
    for i as integer = 0 to ubound(faces)
        faces(i).texture = texture
    next i
    return this
end function
