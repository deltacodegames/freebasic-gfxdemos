' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "object3.bi"
#include once "cframe3.bi"
#include once "mouse2.bi"
#include once "particle3.bi"

enum DebugColors
    AxisX  = &hf00000
    AxisY  = &h00f000
    AxisZ  = &h0000f0
    Normal = &hd00000
    Vertex = &h00d000
end enum

enum DebugFlags
    ShowAxes     = &h01
    ShowNormals  = &h02
    ShowVertexes = &h04
end enum

enum GameFlags
    RenderCursor = &h01
    RenderRadar  = &h02
    ResetMode    = &h04
end enum

enum NavigationModes
    Fly
    Follow
    Orbit
end enum

enum RenderModes
    None
    Solid
    Textured
    Wireframe
    WireframeVertexes
end enum

enum TextureModes
    Auto  = -1
    Best  = 0
    Worst = 7
end enum

type GameSession
    as Object3 ptr     activeObject
    as integer         bgColor
    as CFrame3         camera
    as DebugFlags      debugFlags
    as integer         debugLevel
    as double          deltaTime
    as GameFlags       flags
    as double          fps
    as Object3 ptr     debugObject
    as Mouse2          mouse
    as NavigationModes navMode
    as Object3 ptr     objects(any)
    as Particle3 ptr   particles(any)
    as RenderModes     renderMode
    as TextureModes    textureMode
    as any ptr         textures(any)
    as any ptr         shades(any, any)
    const as integer   GeneratedShadesCount = 16
    as CFrame3         world
    declare function addObject(sid as string, filename as string = "") as Object3 ptr
    declare function addParticle(position as Vector3, colr as integer) as Particle3 ptr
    declare function addTexture(w as integer, h as integer, filename as string = "") as integer
    declare function findObject(sid as string) as Object3 ptr
    declare function free() as GameSession
    declare function generateShades(textureIndex as integer, darkest as double = 0.5, brightest as double = 1.5) as GameSession
    declare function getShade(textureIndex as integer, shadeIndex as integer = -1) as any ptr
    declare function getTexture(index as integer) as any ptr
    declare function nextObject(fromObject as Object3 ptr) as Object3 ptr
end type
