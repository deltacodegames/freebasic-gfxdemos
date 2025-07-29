' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "object3.bi"
#include once "cframe3.bi"
#include once "vector2.bi"

#macro array_append(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
#endmacro

#macro keydown(scanCode, waitVar, codeBlock)
    if multikey(scanCode) and waitVar = -1 then
        waitVar = scanCode
        codeBlock
    elseif not multikey(scanCode) and waitVar = scanCode then
        waitVar = -1
    end if
#endmacro

declare function lerp(from as double, goal as double, a as double = 0.5) as double

declare function getOrientationStats(camera as CFrame3) as string
declare function getLocationStats(camera as CFrame3) as string
declare function object_collection_add(filename as String, collection() as Object3) as Object3 ptr
declare sub printSafe(row as integer, col as integer, text as string, bounds() as integer)
declare sub printStringBlock(row as integer, col as integer, text as string, header as string = "", border as string = "", footer as string = "")
declare function addObject(sid as string, objects() as Object3, filename as string = "") as Object3 ptr
declare function getObjectBySid(sid as string, objects() as Object3) as Object3 ptr
