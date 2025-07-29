' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "object3.bi"
#include once "cframe3.bi"
#include once "mouse2.bi"

enum NavigationMode
    Fly
    Follow
    Orbit
end enum

enum RenderMode
    None
    Solid
    Textured
    Wireframe
end enum

type ScreenMetaType
    as _long_  bpp
    as _long_  depth
    as string  driver
    as _long_  flags
    as _long_  pages
    as _long_  pitch
    as _long_  rate
    as double  ratioh
    as double  ratiow
    as double  viewbtm
    as double  viewlft
    as double  viewrgt
    as double  viewtop
    as _long_  w, h
    declare function applySettings() as integer
    declare function applyView() as ScreenMetaType
    declare function readSettings() as ScreenMetaType
    declare function resetView() as ScreenMetaType
    declare function setView(lft as double, top as double, rgt as double, btm as double) as ScreenMetaType
end type
function ScreenMetaType.applySettings() as integer
    return screenres(w, h, depth, pages, flags, rate)
end function
function ScreenMetaType.applyView() as ScreenMetaType
    window (viewlft, viewtop)-(viewrgt, viewbtm)
    return this
end function
function ScreenMetaType.readSettings() as ScreenMetaType
    screeninfo w, h, depth, bpp, pitch, rate, driver
    ratiow = w / h
    ratioh = h / w
    return this
end function
function ScreenMetaType.resetView() as ScreenMetaType
    window
    return this
end function
function ScreenMetaType.setView(lft as double, top as double, rgt as double, btm as double) as ScreenMetaType
    this.viewlft = lft
    this.viewtop = top
    this.viewrgt = rgt
    this.viewbtm = btm
    return this
end function

type Image32
    as any ptr buffer
    as _long_  bpp
    as _long_  pitch
    as any ptr pixdata
    as string label
    as _long_  w, h
    declare constructor        ()
    declare constructor        (w as _long_, h as _long_, label as string = "")
    declare function create    (w as _long_, h as _long_, label as string = "") as Image32
    declare function free      () as Image32
    declare function getPixel  (x as _long_, y as _long_) as ulong
    declare function getPixel  (x as double, y as double) as ulong
    declare function load      (filename as string) as Image32
    declare function readInfo  (imageBuffer as any ptr) as Image32
    declare function plotPixel (x as _long_, y as _long_, colr as ulong) as Image32
end type
constructor Image32
end constructor
constructor Image32(w as _long_, h as _long_, label as string)
    this.create(w, h, label)
end constructor
function Image32.create(w as _long_, h as _long_, label as string = "") as Image32
    this.label = label
    this.buffer = imagecreate(w, h)
    return this.readInfo(this.buffer)
end function
function image32.free() as Image32
    if this.buffer then
        imagedestroy this.buffer
    end if
    this.buffer  = 0
    this.bpp     = 0
    this.pitch   = 0
    this.pixdata = 0
    this.label   = ""
    this.w       = 0
    this.h       = 0
    return this
end function
function Image32.getPixel(x as _long_, y as _long_) as ulong
    dim as long ptr pixel = this.pixdata + this.pitch * y + x
    return *pixel
end function
function Image32.getPixel(x as double, y as double) as ulong
    dim as long ptr pixel
    dim as long offset
    offset = this.pitch * int(this.h * y) + this.bpp * int(this.w * x)
    pixel = this.pixdata + offset
    return *pixel
end function
function Image32.readInfo(imageBuffer as any ptr) as Image32
    this.buffer = imageBuffer
    imageinfo this.buffer, this.w, this.h, this.bpp, this.pitch, this.pixdata
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

enum GameFlags
    RenderCursor = &h01
    RenderRadar  = &h02
    ResetMode    = &h04
end enum

type GameStateType
    as Object3 ptr    active
    as CFrame3        camera
    as integer        debugLevel
    as double         deltaTime
    as integer        flags
    as double         fps
    as Mouse2         mouse
    as NavigationMode navMode
    as Object3        objects(any)
    as ParticleType   particles(any)
    as CFrame3        world
end type
function hasflag(gameState as GameStateType, flag as integer) as boolean
    return gameState.flags and flag
end function
sub setFlag(gameState as GameStateType, flag as integer)
    gameState.flags = gameState.flags or flag
end sub
sub unsetFlag(gameState as GameStateType, flag as integer)
    gameState.flags = (gameState.flags or flag) xor flag
end sub

declare sub init       (byref gameState as GameStateType)
declare sub initScreen ()
declare sub main       (byref gameState as GameStateType)
declare sub shutdown   (byref gameState as GameStateType)

declare sub handleFlyInput    (byref gameState as GameStateType)
declare sub handleFollowInput (byref gameState as GameStateType)
declare sub handleOrbitInput  (byref gameState as GameStateType)

declare sub drawMouseCursor (byref mouse as Mouse2)
declare sub drawReticle     (byref mouse as Mouse2, reticleColor as integer = &h808080, arrowColor as integer = &hd0b000)
declare sub fpsUpdate       (byref fps as integer)
declare sub printDebugInfo  (byref gameState as GameStateType)
declare sub renderFrame     (byref gameState as GameStateType)
declare sub renderUI        (byref gameState as GameStateType)

declare sub animateAsteroid(byref o as Object3, byref camera as CFrame3, byref world as CFrame3, deltaTime as double)
