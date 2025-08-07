type Vector2
    x as double
    y as double
end type
declare operator int (a as Vector2) as Vector2
declare operator - (a as Vector2) as Vector2
declare operator + (a as Vector2, b as Vector2) as Vector2
declare operator + (a as Vector2, b as double) as Vector2
declare operator - (a as Vector2, b as Vector2) as Vector2
declare operator - (a as Vector2, b as double) as Vector2
declare operator * (a as Vector2, b as double) as Vector2
declare operator * (a as Vector2, b as Vector2) as Vector2
declare operator / (a as Vector2, b as double) as Vector2
declare operator / (a as Vector2, b as Vector2) as Vector2
declare operator \ (a as Vector2, b as double) as Vector2
declare operator \ (a as Vector2, b as Vector2) as Vector2
declare function cross(a as Vector2, b as Vector2) as double
declare function dot(a as Vector2, b as Vector2) as double
declare function length(a as Vector2) as double
declare function normalize(a as Vector2) as Vector2

dim as Vector2 axisA, axisB, axisC
dim as Vector2 A, B, C, p
dim as integer lft, rgt, top, btm
dim as integer red, grn, blu
dim as integer xres, yres
dim as double u, v, w
dim as double colors(2, 2) = {_
    {1, 1, 1},_
    {1, 1, 0},_
    {0, 0, 1} _
}
xres = 800: yres = 800

' triangle coords
A = type(   0, -1/2) * type<Vector2>(xres, yres)/2 + type<Vector2>(xres, yres)\2
B = type(-1/2,  1/3) * type<Vector2>(xres, yres)/2 + type<Vector2>(xres, yres)\2
C = type( 1/2,  1/3) * type<Vector2>(xres, yres)/2 + type<Vector2>(xres, yres)\2
A = int(A)
B = int(B)
C = int(C)

' start
screenres 800, 800, 32

' draw grid
line (0, yres\2)-(xres-1, yres\2), &h808080, , &hf0f0
line (xres\2, 0)-(xres\2, yres-1), &h808080, , &hf0f0

' draw triangle border (supposed to be all covered if correct)
line(A.x, A.y)-(B.x, B.y), &hff0000
line(B.x, B.y)-(C.x, C.y), &h00ff00
line(C.x, C.y)-(A.x, A.y), &h0000ff

' calculate pixel scan area
lft = iif(A.x < B.x, iif(A.x < C.x, A.x, C.x), iif(B.x < C.x, B.x, C.x))
rgt = iif(A.x > B.x, iif(A.x > C.x, A.x, C.x), iif(B.x > C.x, B.x, C.x))
top = iif(A.y < B.y, iif(A.y < C.y, A.y, C.y), iif(B.y < C.y, B.y, C.y))
btm = iif(A.y > B.y, iif(A.y > C.y, A.y, C.y), iif(B.y > C.y, B.y, C.y))
line (lft, top)-(rgt, btm), &hffffff, b, &hdddd

axisA = B + normalize(C-B) * dot(normalize(C-B), A-B) - A
axisB = C + normalize(C-A) * dot(normalize(C-A), B-C) - B
axisC = A + normalize(B-A) * dot(normalize(B-A), C-A) - C

screenlock
for y as integer = top to btm
    for x as integer = lft to rgt
        p = type<Vector2>(x, y)
        u = 1-dot(p-A, normalize(axisA)) / length(axisA)
        v = 1-dot(p-B, normalize(axisB)) / length(axisB)
        w = 1-dot(p-C, normalize(axisC)) / length(axisC)
        if u < 0 or v < 0 or w < 0 then continue for
        if u > 1 or v > 1 or w > 1 then continue for
        red = int(255 * (u*colors(0,0)+v*colors(1,0)+w*colors(2,0)))
        grn = int(255 * (u*colors(0,1)+v*colors(1,1)+w*colors(2,1)))
        blu = int(255 * (u*colors(0,2)+v*colors(1,2)+w*colors(2,2)))
        pset (x, y), rgb(red, grn, blu)
    next x
next y
screenunlock
sleep
end

operator int (a as Vector2) as Vector2
    return type(int(a.x), int(a.y))
end operator
operator - (a as Vector2) as Vector2
    return type(-a.x, -a.y)
end operator
operator + (a as Vector2, b as Vector2) as Vector2
    return type(a.x+b.x, a.y+b.y)
end operator
operator + (a as Vector2, b as double) as Vector2
    return type(a.x+b, a.y+b)
end operator
operator - (a as Vector2, b as Vector2) as Vector2
    return a + -b
end operator
operator - (a as Vector2, b as double) as Vector2
    return a + -b
end operator
operator * (a as Vector2, b as double) as Vector2
    return type(a.x*b, a.y*b)
end operator
operator * (a as Vector2, b as Vector2) as Vector2
    return type(a.x*b.x, a.y*b.y)
end operator
operator / (a as Vector2, b as double) as Vector2
    return type(a.x/b, a.y/b)
end operator
operator / (a as Vector2, b as Vector2) as Vector2
    return type(a.x/b.x, a.y/b.y)
end operator
operator \ (a as Vector2, b as double) as Vector2
    return type(a.x\b, a.y\b)
end operator
operator \ (a as Vector2, b as Vector2) as Vector2
    return type(a.x\b.x, a.y\b.y)
end operator
function cross(a as Vector2, b as Vector2) as double
    return a.x*b.y - a.y*b.x
end function
function dot(a as Vector2, b as Vector2) as double
    return a.x*b.x + a.y*b.y
end function
function length(a as Vector2) as double
    return sqr(a.x*a.x+a.y*a.y)
end function
function normalize(a as Vector2) as Vector2
    return type(a.x, a.y) / length(a)
end function
