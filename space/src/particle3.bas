' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "particle3.bi"

#define pi 3.1415926535
#define clamp(value, min, max) iif(value < min, min, iif(value > max, max, value))
#define rgb_r(c) (c shr 16 and &hff)
#define rgb_g(c) (c shr  8 and &hff)
#define rgb_b(c) (c        and &hff)

constructor Particle3
    randomizeTwinkle()
end constructor
constructor Particle3 (position as Vector3, colr as integer)
    this.position = position
    this.colr = colr
    randomizeTwinkle()
end constructor
function Particle3.getTwinkleColor() as integer
    dim as integer r, g, b
    dim as double shift = _
    twinkleAmp * sin(2 * pi * frac(timer * twinkleFreq) + twinklePhase)
    r = clamp(rgb_r(colr) + int(shift), 0, 255)
    g = clamp(rgb_g(colr) + int(shift), 0, 255)
    b = clamp(rgb_b(colr) + int(shift), 0, 255)
    return rgb(r, g, b)
end function
sub Particle3.randomizeTwinkle()
    twinkleAmp   = rnd * 32
    twinkleFreq  = rnd * 1
    twinklePhase = rnd * 2 * pi
end sub
