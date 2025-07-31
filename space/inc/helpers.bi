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

declare function hasflag(byref flags as integer, flag as integer) as boolean
declare sub setFlag(byref flags as integer, flag as integer)
declare sub unsetFlag(byref flags as integer, flag as integer)

declare function lerp(from as double, goal as double, a as double = 0.5) as double

declare function getOrientationStats(camera as CFrame3) as string
declare function getLocationStats(camera as CFrame3) as string
declare sub printStringBlock(row as integer, col as integer, text as string, header as string = "", border as string = "", footer as string = "")
