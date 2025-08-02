' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#ifdef __FB_64BIT__
    #define _long_ longint
#else
    #define _long_ long
#endif

enum Mouse2Event
    LeftDown = 0
    LeftUp
    MiddleDown
    MiddleUp
    Move
    RightDown
    RightUp
    WheelChange
    __
    MAX_VALUE = __ - 1
end enum
enum Mouse2Mode
    Standard = 0
    Viewport
end enum
type Mouse2
private:
    _buttonsPrev as _long_
    _dragFromX as double
    _dragFromY as double
    _dragDeltaX as double
    _dragDeltaY as double
    _events(Mouse2Event.MAX_VALUE) as boolean
    _isVisible as boolean = true
    _mode as integer = Mouse2Mode.Standard
    _wheelPrev as _long_
    _wheelDelta as _long_
    _xPrev as double
    _xDelta as double
    _yPrev as double
    _yDelta as double
public:
    x as double
    y as double
    wheel as _long_
    buttons as _long_
    clipped as _long_
    status as _long_
    declare constructor ()
    declare constructor (initMode as integer)
    declare property deltaX         as double
    declare property deltaY         as double
    declare property dragX          as double
    declare property dragY          as double
    declare property fromX          as double
    declare property fromY          as double
    declare property leftClicked    as boolean
    declare property leftReleased   as boolean
    declare property leftDown       as boolean
    declare property leftUp         as boolean
    declare property middleClicked  as boolean
    declare property middleReleased as boolean
    declare property middleDown     as boolean
    declare property middleUp       as boolean
    declare property moved          as boolean
    declare property rightClicked   as boolean
    declare property rightReleased  as boolean
    declare property rightDown      as boolean
    declare property rightUp        as boolean
    declare property visible        as boolean
    declare property wheelChanged   as boolean
    declare property wheelDelta     as _long_
    declare sub clip()
    declare sub unclip()
    declare sub hide()
    declare sub show()
    declare sub update()
    declare sub setMode(newMode as integer)
end type
