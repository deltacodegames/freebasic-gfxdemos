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

#macro array_append_return_ubound(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
    return ubound(arr)
#endmacro

function Mesh3.addFace(face as Face3) as Mesh3
    array_append(faces, face)
    faces(ubound(faces)).id = ubound(faces)
    return this
end function
'~ function Mesh3.getAverageTextureFaceColor() as integer
    '~ dim as Mesh3 mesh = spaceship->mesh
    '~ dim as Face3 face
    '~ dim as Vector2 uv(2)
    '~ dim as integer colr, r, g, b, n
    '~ dim as double rsum, gsum, bsum
    '~ for i as integer = 0 to ubound(mesh.faces)
        '~ face = mesh.faces(i)
        '~ uv(0) = mesh.getUv(face.uvIds(0))
        '~ for j as integer = 1 to ubound(face.uvIds)-1
            '~ uv(1) = mesh.getUv(face.uvIds(j))
            '~ uv(2) = mesh.getUv(face.uvIds(j+1))
            '~ for k as integer = 0 to ubound(uv)
                '~ colr = uvToColor(uv(k).x, uv(k).y)
                '~ rsum += rgb_r(colr)/255
                '~ gsum += rgb_g(colr)/255
                '~ bsum += rgb_b(colr)/255
                '~ n += 1
            '~ next k
        '~ next j
        '~ r = int(255*(rsum/n))
        '~ g = int(255*(gsum/n))
        '~ b = int(255*(bsum/n))
        '~ spaceship->mesh.faces(i).colr = rgb(r, g, b)
    '~ next i
'~ end function
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
function Mesh3.buildBsp() as Mesh3
    dim as integer faceIds(any)
    for i as integer = 0 to ubound(faces)
        if ubound(faces(i).vertexes) >= 0 then
            array_append(faceIds, faces(i).id)
        end if
        bspRoot = splitBsp(faceIds())
    next i
    return this
end function
function Mesh3.splitBsp(faceIds() as integer) as BspNode3 ptr
    dim as BspNode3 ptr node
    dim as Face3 face, behind, infront, nearest, splitter
    dim as integer backId =- -1, frontId = -1, backs(any), fronts(any)
    dim as Vector3 average, backSum, frontSum, rootSum

    if ubound(faceIds) = -1 then return 0

    node = new BspNode3
    select case 1
    case 0 '- average vertex point
        for i as integer = 0 to ubound(faceIds)
            face = getFace(faceIds(i))
            rootSum += face.position
        next i
        average = rootSum / (ubound(faceIds) + 1)
        
        nearest = getFace(faceIds(0))
        for i as integer = 1 to ubound(faceIds)
            face = getFace(faceIds(i))
            if (face.position - average).length < (nearest.position - average).length then
                nearest = face
            end if
        next i
    case 1 '- max area
        dim as double compare, comparator
        dim as Vector3 a, b, c
        nearest = getFace(faceIds(0))
        for i as integer = 0 to ubound(faceIds)
            face = getFace(faceIds(i))
            a = face.vertexes(0)
            b = face.vertexes(1)
            c = face.vertexes(2)
            compare = cross(b - a, c - a).length
            if compare > comparator then
                comparator = compare
                nearest = face
            end if
        next i
    case 2 '- min area between average and normal
        for i as integer = 0 to ubound(faceIds)
            face = getFace(faceIds(i))
            rootSum += face.position
        next i
        average = rootSum / (ubound(faceIds) + 1)
        
        dim as double compare, comparator
        dim as Vector3 a, b, c
        nearest = getFace(faceIds(0))
        for i as integer = 0 to ubound(faceIds)
            face = getFace(faceIds(i))
            compare = cross(face.normal, average - face.position).length
            if compare < comparator then
                comparator = compare
                nearest = face
            end if
        next i
    end select
    
    node->faceId = nearest.id
    splitter = getFace(nearest.id)
    for i as integer = 0 to ubound(faceIds)
        face = getFace(faceIds(i))
        if face.id <> splitter.id then
            if dot(splitter.normal, face.position - splitter.position) <= 0 then
                array_append(backs, face.id)
                backSum += face.position
            else
                array_append(fronts, face.id)
                frontSum += face.position
            end if
        end if
    next i

    if ubound(backs) >= 0 then
        average = backSum / (ubound(backs) + 1)
        backId  = backs(0)
        behind  = getFace(backId)
        for i as integer = 1 to ubound(backs)
            face = getFace(backs(i))
            if (face.position - average).length < (behind.position - average).length then
                backId = face.id
            end if
        next i
    end if
    if ubound(fronts) >= 0 then
        average = frontSum / (ubound(fronts) + 1)
        frontId = fronts(0)
        infront = getFace(frontId)
        for i as integer = 1 to ubound(fronts)
            face = getFace(fronts(i))
            if (face.position - average).length < (infront.position - average).length then
                frontId = face.id
            end if
        next i
    end if

    if backId >= 0 then
        node->behind  = splitBsp(backs())
    end if
    if frontId >= 0 then
        node->infront = splitBsp(fronts())
    end if
    
    return node
end function
function Mesh3.getFace(faceId as integer) as Face3
if faceId > ubound(this.faces) then
    print faceId
    sleep
    end
end if
    return this.faces(faceId)
end function
function Mesh3.paintFaces(colr as integer) as Mesh3
    for i as integer = 0 to ubound(faces)
        faces(i).colr = colr
    next i
    return Mesh3
end function
function Mesh3.textureFaces(texture as any ptr) as Mesh3
    for i as integer = 0 to ubound(faces)
        faces(i).texture = texture
    next i
    return Mesh3
end function
