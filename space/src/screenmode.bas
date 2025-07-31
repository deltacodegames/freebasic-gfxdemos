' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "screenmode.bi"

function ScreenModeType.applySettings() as integer
    dim as integer result = screenres(w, h, depth, pages, flags, rate)
    if result = 0 then
        readSettings()
    end if
    return result
end function
function ScreenModeType.applyView() as ScreenModeType
    window (viewlft, viewtop)-(viewrgt, viewbtm)
    return this
end function
function ScreenModeType.readSettings() as ScreenModeType
    screeninfo w, h, depth, bpp, pitch, rate, driver
    ratiow = w / h
    ratioh = h / w
    return this
end function
function ScreenModeType.resetView() as ScreenModeType
    window
    return this
end function
function ScreenModeType.setView(lft as double, top as double, rgt as double, btm as double) as ScreenModeType
    this.viewlft = lft
    this.viewtop = top
    this.viewrgt = rgt
    this.viewbtm = btm
    return this
end function
