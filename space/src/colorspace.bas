' -----------------------------------------------------------------------------
' Copyright (c) 2026 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "colorspace.bi"

#define clamp(value, min, max) iif(value < min, min, iif(value > max, max, value))
#define pi 3.1415926535

namespace ColorSpace2

    type ColorVertex
        colr as integer
        intensity as double
        position as Vector2
        declare constructor ()
        declare constructor (position as Vector2, colr as integer, intensity as double)
    end type
    constructor ColorVertex
    end constructor
    constructor ColorVertex (position as Vector2, colr as integer, intensity as double)
        this.position  = position
        this.colr      = colr
        this.intensity = intensity
    end constructor

    function SampleColor overload (sample as Vector2, variant as integer = 1) as integer
        dim as Vector2 ar, ag, ab
        dim as double r, g, b
        select case variant
            case 1
                dim as ColorVertex lights(3) = _
                {_
                    type(Vector2(0/3*pi)/2, &hff0000, 1),_
                    type(Vector2(2/3*pi)/2, &h00ff00, 1),_
                    type(Vector2(4/3*pi)/2, &h0000ff, 1),_
                    type(Vector2(0, 0)  , &hffffff, 1) _
                }
                for i as integer = 0 to ubound(lights)
                    dim as Vector2 p = lights(i).position
                    dim as integer c = lights(i).colr
                    dim as double  m = lights(i).intensity
                    dim as double  d = clamp(1-sin((p - sample).length), 0, 1)
                    r += int(d * m * (c shr 16 and &hff))
                    g += int(d * m * (c shr  8 and &hff))
                    b += int(d * m * (c        and &hff))
                next i
                return rgb(clamp(r,0,255), clamp(g,0,255), clamp(b,0,255))
            case 2
                dim as ColorVertex lights(4) = _
                {_
                    type(Vector2(0/4*pi)*0, &hffffff, 1),_
                    type(Vector2(0/4*pi)*1, &h0000ff, 1/2),_
                    type(Vector2(2/4*pi)*1, &h0000ff, 1/2),_
                    type(Vector2(4/4*pi)*1, &h0000ff, 1/2),_
                    type(Vector2(6/4*pi)*1, &h0000ff, 1/2) _
                }
                for i as integer = 0 to ubound(lights)
                    dim as Vector2 p = lights(i).position
                    dim as integer c = lights(i).colr
                    dim as double  m = lights(i).intensity
                    dim as double  d = clamp(1-sin((p - sample).length), 0, 1)
                    r += int(d * m * (c shr 16 and &hff))
                    g += int(d * m * (c shr  8 and &hff))
                    b += int(d * m * (c        and &hff))
                next i
                return rgb(clamp(r,0,255), clamp(g,0,255), clamp(b,0,255))
            case 3
                dim as ColorVertex lights(6) = _
                {_
                    type(Vector2(4/4*pi)*0, &hffffff, 1),_
                    type(Vector2(2/4*pi)*1, &h0000ff, 1),_
                    type(Vector2(3/4*pi)*1, &h0000ff, 1),_
                    type(Vector2(4/4*pi)*1, &h0000ff, 1),_
                    type(Vector2(5/4*pi)*1, &h0000ff, 1),_
                    type(Vector2(7/4*pi)*1/2, &hff0000, 1),_
                    type(Vector2(1/4*pi)*1, &hffff00, 1) _
                }
                for i as integer = 0 to ubound(lights)
                    dim as Vector2 p = lights(i).position
                    dim as integer c = lights(i).colr
                    dim as double  m = lights(i).intensity
                    dim as double  d = clamp(1-sin((p - sample).length), 0, 1)
                    r += int(d * m * (c shr 16 and &hff))
                    g += int(d * m * (c shr  8 and &hff))
                    b += int(d * m * (c        and &hff))
                next i
                return rgb(clamp(r,0,255), clamp(g,0,255), clamp(b,0,255))
            case 4
                ar = Vector2(2*pi*1/1)
                ag = Vector2(2*pi*1/3)
                ab = Vector2(2*pi*2/3)
                r = clamp(sin(1-(ar - sample).length), 0, 1)
                g = clamp(sin(1-(ag - sample).length), 0, 1)
                b = clamp(sin(1-(ab - sample).length), 0, 1)
            case 5
                ar = Vector2(2*pi*1/1)
                ag = Vector2(2*pi*1/3)
                ab = Vector2(2*pi*2/3)
                r = clamp(sin(2-(ar - sample).length), 0, 1)
                g = clamp(sin(2-(ag - sample).length), 0, 1)
                b = clamp(sin(2-(ab - sample).length), 0, 1)
        end select
        return rgb(int(255*r), int(255*g), int(255*b))
    end function

    function SampleColor overload(radians as double, magnitude as double=1, variant as integer = 1) as integer
        return SampleColor(Vector2(radians) * magnitude, variant)
    end function
    
end namespace
