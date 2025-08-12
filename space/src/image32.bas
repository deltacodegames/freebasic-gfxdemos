' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "image32.bi"

function Image32.getPixel(x as _long_, y as _long_) as ulong
    dim as ulong ptr pixel
    dim as _long_ offset
    offset = this.pitch * y + this.bpp * x
    pixel = this.pixdata + offset
    return *pixel
end function
function Image32.getPixel(x as double, y as double) as ulong
    dim as ulong ptr pixel
    dim as _long_ offset
    offset = this.pitch * int(this.h * y) + this.bpp * int(this.w * x)
    pixel = this.pixdata + offset
    return *pixel
end function
function Image32.getPixelSafe(x as _long_, y as _long_) as ulong
    dim as ulong ptr pixel
    dim as _long_ offset
    offset = this.pitch * y + this.bpp * x
    if offset >= 0 and offset < this.pixrange then
        pixel = this.pixdata + offset
        return *pixel
    else
        return 0
    end if
end function
function Image32.getPixelSafe(x as double, y as double) as ulong
    dim as ulong ptr pixel
    dim as _long_ offset
    offset = this.pitch * int(this.h * y) + this.bpp * int(this.w * x)
    if offset >= 0 and offset < this.pixrange then
        pixel = this.pixdata + offset
        return *pixel
    else
        return 0
    end if
end function
function Image32.readInfo(imageBuffer as any ptr) as Image32
    this.resetInfo
    if imageinfo(imageBuffer, this.w, this.h, this.bpp, this.pitch, this.pixdata) <> 1 then
        this.buffer = imageBuffer
        this.pixrange = this.pitch * (this.h + 1) - 1
    end if
    return this
end function
function Image32.putPixel(x as _long_, y as _long_, colr as ulong) as Image32
    dim as ulong ptr pixel
    dim as _long_ offset
    offset = this.pitch * y + this.bpp * x
    pixel = this.pixdata + offset
    *pixel = colr
    return this
end function
function Image32.resetInfo() as Image32
    this.buffer   = 0
    this.bpp      = 0
    this.pitch    = 0
    this.pixdata  = 0
    this.pixrange = 0
    this.w        = 0
    this.h        = 0
    return this
end function
