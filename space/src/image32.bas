' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "image32.bi"

constructor Image32
end constructor
constructor Image32(w as _long_, h as _long_, label as string)
    this.create(w, h, label)
end constructor
function Image32.create(w as _long_, h as _long_, label as string = "") as Image32
    this.label = label
    this.buffer = imagecreate(w, h)
    if this.buffer then
        this.readInfo(this.buffer)
    end if
    return this
end function
function image32.free() as Image32
    if this.buffer then
        imagedestroy this.buffer
    end if
    this.buffer   = 0
    this.bpp      = 0
    this.pitch    = 0
    this.pixdata  = 0
    this.pixrange = 0
    this.label    = ""
    this.w        = 0
    this.h        = 0
    return this
end function
function Image32.getPixel(x as _long_, y as _long_) as ulong
    dim as long ptr pixel
    dim as long offset
    offset = this.pitch * y + x
    if offset < this.pixrange then
        pixel = this.pixdata + offset
        return *pixel
    end if
    return 0
end function
function Image32.getPixel(x as double, y as double) as ulong
    dim as long ptr pixel
    dim as long offset
    offset = this.pitch * int(this.h * y) + this.bpp * int(this.w * x)
    if offset < this.pixrange then
        pixel = this.pixdata + offset
        return *pixel
    end if
    return 0
end function
function Image32.readInfo(imageBuffer as any ptr) as Image32
    if imageinfo(imageBuffer, this.w, this.h, this.bpp, this.pitch, this.pixdata) <> 1 then
        this.buffer = imageBuffer
        this.pixrange = this.pitch * this.h
    end if
    return this
end function
function Image32.load(filename as string) as Image32
    if this.buffer then
        bload filename, this.buffer
    end if
    return this
end function
function Image32.plotPixel(x as _long_, y as _long_, colr as ulong) as Image32
    dim as ulong ptr pixel
    dim as integer offset
    offset = this.pitch * y + this.bpp * x
    pixel = this.pixdata + offset
    *pixel = colr
    return this
end function
