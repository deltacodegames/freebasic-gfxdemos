' -----------------------------------------------------------------------------
' Copyright (c) 2026 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "vector2.bi"

namespace ColorSpace2

    declare function SampleColor overload(va as Vector2, variant as integer = 1) as integer
    declare function SampleColor overload(a as double, m as double=1, variant as integer = 1) as integer
    
end namespace
