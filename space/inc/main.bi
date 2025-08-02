' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "gamesession.bi"
#include once "object3.bi"
#include once "cframe3.bi"
#include once "mouse2.bi"

declare sub init       (byref game as GameSession)
declare sub initScreen ()
declare sub main       (byref game as GameSession)
declare sub shutdown   (byref game as GameSession)

declare sub handleFlyInput    (byref game as GameSession)
declare sub handleFollowInput (byref game as GameSession)
declare sub handleOrbitInput  (byref game as GameSession)

declare sub drawAxes        (byref game as GameSession)
declare sub drawMouseCursor (byref game as GameSession)
declare sub drawNormals     (byref game as GameSession)
declare sub drawReticle     (byref mouse as Mouse2, reticleColor as integer = &h808080, arrowColor as integer = &hd0b000)
declare sub drawVertexes    (byref game as GameSession)
declare sub fpsUpdate       (byref fps as integer)
declare sub printDebugInfo  (byref game as GameSession)
declare sub renderFrame     (byref game as GameSession)
declare sub renderUI        (byref game as GameSession)

declare sub animateAsteroid(byref o as Object3, byref camera as CFrame3, byref world as CFrame3, deltaTime as double)
