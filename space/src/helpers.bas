' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "helpers.bi"
#include once "vector3.bi"

#define format_decimal(f, p) iif(f >= 0, " ", "-") + str(abs(fix(f))) + "." + str(int(abs(frac(f)) * 10^p))

function lerp(from as double, goal as double, a as double = 0.5) as double
    return from + (goal - from) * a
end function

function getOrientationStats(camera as CFrame3) as string
    dim as string stats(3, 3)
    for i as integer = 0 to 2
        dim as Vector3 o = camera.orientation.matrix(i)
        stats(i, 0) = format_decimal(o.x, 2)
        stats(i, 1) = format_decimal(o.y, 2)
        stats(i, 2) = format_decimal(o.z, 2)
    next i
    dim as integer roww = 21
    dim as integer colw = 8
    dim as string body   = ""
    dim as string row
    for i as integer = 0 to 2
        dim as string row = space(roww)
        for j as integer = 0 to 2
            mid(row, 1+j*colw) = stats(i, j)
        next j
        body += row + iif(i < 2, "$$", "")
    next i
    return body
end function

function getLocationStats(camera as CFrame3) as string
    dim as string axisNames(2) = {"X", "Y", "Z"}
    dim as integer roww = 21
    dim as integer colw = 8
    dim as string body = ""
    dim as string row  = space(roww)
    
    mid(row, 1+0*colw) = format_decimal(camera.position.x, 1)
    mid(row, 1+1*colw) = format_decimal(camera.position.y, 1)
    mid(row, 1+2*colw) = format_decimal(camera.position.z, 1)
    
    return body + row
end function

sub printSafe(row as integer, col as integer, text as string, bounds() as integer)
    dim as integer clip0 = 1, clip1 = len(text)
    if row >= bounds(0) and row <= bounds(2) then
        if col+len(text) >= bounds(1) and col <= bounds(3) then
            if col < bounds(1) then
                clip0 += bounds(1) - col
                clip1 -= bounds(1) - col
            end if
            if col + clip1 > bounds(3) then
                clip1 -= (col + clip1) - bounds(3)
            end if
            locate row, col + (clip0 - 1)
            print mid(text, clip0, clip1);
        end if
    end if
end sub

sub printStringBlock(row as integer, col as integer, text as string, header as string = "", border as string = "", footer as string = "")
    dim as integer i = 1, j, maxw
    dim as string s
    while i > 0
        j = instr(i, text, "$")
        if j then
            s = mid(text, i, j-i)
            i = j+1
        else
            s = mid(text, i)
            i = 0
        end if
        if len(s) > maxw then
            maxw = len(s)
        end if
    wend
    if header <> "" then
        dim as string buffer = string(maxw, iif(border <> "", border, " "))
        mid(buffer, 1) = header
        locate   row, col: print buffer;
        locate row+1, col: print string(maxw, " ");
        row += 2
    end if
    i = 1
    while i > 0
        j = instr(i, text, "$")
        if j then
            s = mid(text, i, j-i)
            i = j+1
        else
            s = mid(text, i)
            i = 0
        end if
        if s = "" then
            s = space(maxw)
        end if
        locate row, col: print s;
        row += 1
    wend
    if footer <> "" then
        locate row, col: print string(maxw, footer);
    end if
end sub

function addObject(sid as string, objects() as Object3, filename as string = "") as Object3 ptr
    dim as Object3 o = type(sid, filename)
    array_append(objects, o)
    return @objects(ubound(objects))
end function

function getObjectBySid(sid as string, objects() as Object3) as Object3 ptr
    for i as integer = 0 to ubound(objects)
        if objects(i).sid = sid then
            return @objects(i)
        end if
    next i
end function
