

#cmdline "-i ../space/src/inc/"
#cmdline "-b ../space/src/vector2.bas"

#include once "vector2.bi"
#include once "fbgfx.bi"
using fb

const pi = 3.141592

'randomize 1111 'intersection
'randomize 1117 'intersection
'randomize 1227 'no intersection
'randomize 1337 'no intersection
randomize 1447 'intersection


enum LineStyle
    dash      = &b1111000011110000
    dot       = &b1000100010001000
    longDash  = &b1111110011111100
    shortDash = &b1100110011001100
    solid     = &b1111111111111111
end enum

type LineSegment2
    const DefaultColor = &hffffffff
    as Vector2 a, b
    as integer colr
    declare constructor ()
    declare constructor (a as Vector2, b as Vector2, colr as integer = DefaultColor)
    declare constructor (a as double, b as double, x as double, y as double, colr as integer = DefaultColor)
    declare property x0 as double
    declare property x1 as double
    declare property y0 as double
    declare property y1 as double
    declare property vector as Vector2
end type
constructor LineSegment2
end constructor
constructor LineSegment2 (a as Vector2, b as Vector2, colr as integer = DefaultColor)
    this.a = a
    this.b = b
    this.colr = colr
end constructor
constructor LineSegment2 (a as double, b as double, x as double, y as double, colr as integer = DefaultColor)
    this.a = type(a, b)
    this.b = type(x, y)
    this.colr = colr
end constructor
property LineSegment2.x0 as double: return a.x: end property
property LineSegment2.x1 as double: return b.x: end property
property LineSegment2.y0 as double: return a.y: end property
property LineSegment2.y1 as double: return b.y: end property
property LineSegment2.vector as Vector2
    return b - a
end property

sub drawLineSegment (a as LineSegment2, style as integer = &hffff)
    line (a.x0, a.y0)-(a.x1, a.y1), a.colr, , style
    line (a.x0-1/4, a.y0+1/4)-step(1/2, -1/2), a.colr, b, style
    line (a.x1-1/8, a.y1+1/8)-step(1/4, -1/4), a.colr, b, style
end sub

sub drawVector (v as Vector2, offset as Vector2 = type(0, 0), colr as integer = &hffffffff, style as integer = LineStyle.solid)
    line (offset.x, offset.y)-step(v.x, v.y), colr, , style
    line (offset.x-1/4, offset.y+1/4)-step(1/2, -1/2), colr, b, style
    line (offset.x+v.x-1/8, offset.y+v.y+1/8)-step(1/4, -1/4), colr, b, style
end sub

sub drawThickVector (v as Vector2, offset as Vector2 = type(0, 0), colr as integer = &hffffffff, style as integer = LineStyle.solid)
    dim as double thickness = abs(pmap(0,2)-pmap(1,2))
    for y as integer = -1 to 1
        dim as Vector2 o = offset + normalize(v).rotatedRight * y * thickness
        line (o.x, o.y)-step(v.x, v.y), colr, , style
    next y
end sub

sub drawCircle (origin as Vector2, r as double, colr as integer = &hffffffff, style as integer = LineStyle.solid)
    if style = LineStyle.solid then
        circle (origin.x, origin.y), r, colr
    else
        dim as double slice = pi/4
        for i as integer = 0 to 15
            if (style shr i) and 1 then
                for a as double = (15-i)*slice/16 to 2*pi step slice
                    circle (origin.x, origin.y), r, colr, a, a+slice/16
                next a
            end if
        next i
    end if
end sub

sub drawGrid(gridColor as integer = &h606060, axisColor as integer = &h808080)
    for i as integer = -10 to 10 step 2
        if i = 0 then
            line ( i, -10)-( i, 10), axisColor, , LineStyle.dash
            line (-10,  i)-(10,  i), axisColor, , LineStyle.dash
        else
            line ( i, -10)-( i, 10), gridColor, , LineStyle.dot
            line (-10,  i)-(10,  i), gridColor, , LineStyle.dot
        end if
    next i
end sub

function render() as LineSegment2
    dim as LineSegment2 a, b

    a = type(Vector2(rnd, rnd)*10, Vector2(rnd, rnd)*10, &hff0000)
    b = type(Vector2(rnd, rnd)*10, Vector2(rnd, rnd)*10, &h00ff00)

    drawGrid

    dim as Vector2 adot = normalize(a.vector)*dot(normalize(a.vector), b.vector)
    dim as Vector2 bdot = normalize(b.vector)*dot(normalize(b.vector), a.vector)

    dim as Vector2 intersection
    dim as Vector2 apos, bpos
    apos = (a.a + a.b)/2
    bpos = (b.a + b.b)/2
    dim as Vector2 anorm, bnorm
    anorm = normalize((a.b - a.a).rotatedRight())
    bnorm = normalize((b.b - b.a).rotatedRight())
    line (apos.x, apos.y)-step(anorm.x, anorm.y), &hffcc00
    line (bpos.x, bpos.y)-step(bnorm.x, bnorm.y), &hffcc00
    dim as double aside0, bside0
    dim as double aside1, bside1
    dim as double aside, bside
    aside0 = dot(bnorm, a.a - bpos)
    bside0 = dot(bnorm, a.b - bpos)
    aside1 = dot(anorm, b.a - apos)
    bside1 = dot(anorm, b.b - apos)
    if (aside0 < 0 and bside0 < 0) or (aside0 > 0 and bside0 > 0) or _
       (aside1 < 0 and bside1 < 0) or (aside1 > 0 and bside1 > 0) then
        '- no intersection
    else
        aside = aside0
        bside = bside0
        if (aside > 0 and bside < 0) or (aside < 0 and bside > 0) then
            intersection = a.a + a.vector * abs(aside) / (abs(aside) + abs(bside))
            drawCircle intersection, 1, &hffff00, LineStyle.dot
            line (intersection.x, intersection.y+1)-step(0, -2), &hffffff, , LineStyle.dot
            line (intersection.x-1, intersection.y)-step(2, 0), &hffffff, , LineStyle.shortDash
            line (intersection.x-2/3, intersection.y+2/3)-step(4/3, -4/3), &hffffff, , LineStyle.shortDash
            line (intersection.x+2/3, intersection.y+2/3)-step(-4/3, -4/3), &hffffff, , LineStyle.shortDash
        end if
        aside = aside1
        bside = bside1
        if (aside > 0 and bside < 0) or (aside < 0 and bside > 0) then
            intersection = b.a + b.vector * abs(aside) / (abs(aside) + abs(bside))
            drawCircle intersection, 0.9, &h00ffff, LineStyle.dot
            line (intersection.x, intersection.y+0.9)-step(0, -2), &hffffff, , LineStyle.dot
            line (intersection.x-0.9, intersection.y)-step(2, 0), &hffffff, , LineStyle.shortDash
            line (intersection.x-2/3+0.1, intersection.y+2/3-0.1)-step(4/3-0.1, -4/3+0.1), &hffffff, , LineStyle.shortDash
            line (intersection.x+2/3-0.1, intersection.y+2/3-0.1)-step(-4/3+0.1, -4/3+0.1), &hffffff, , LineStyle.shortDash
        end if
    end if
    drawLineSegment a
    drawLineSegment b
    drawVector a.vector, , a.colr, LineStyle.longDash
    drawVector b.vector, , b.colr, LineStyle.longDash
    
    drawThickVector adot, , a.colr, LineStyle.solid
    drawThickVector bdot, , b.colr, LineStyle.solid
    drawVector a.vector - bdot, bdot, b.colr, LineStyle.dot
    drawVector b.vector - adot, adot, a.colr, LineStyle.dot

    drawVector a.a - b.a, , , LineStyle.dot

    dim as Vector2 m(3) = {a.a, a.b, b.a, b.b}
    dim as double longestDiagonal = 0
    for i as integer = 0 to ubound(m)
        for j as integer = 0 to ubound(m)
            if i <> j then
                dim as double length = (m(i) - m(j)).length
                if length > longestDiagonal then
                    longestDiagonal = length
                end if
            end if
        next j
    next i
    return LineSegment2(intersection, Vector2(longestDiagonal/2, longestDiagonal/2))
end function

screenres 800, 800, 32
window (-10, 10)-(10, -10)

dim as LineSegment2 area = render

view (pmap(1, 0), pmap(-1, 1))-(pmap(9, 0), pmap(-9, 1)), &h202020, &h808080
window (area.a.x-area.b.x/2, area.a.y+area.b.y/2)-(area.a.x+area.b.x/2, area.a.y-area.b.y/2)
render

sleep
end
