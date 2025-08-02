#include once "mouse2.bi"

constructor Mouse2
end constructor
constructor Mouse2(initMode as integer)
    _mode = initMode
end constructor
property Mouse2.deltaX         as double : return _xDelta                         : end property
property Mouse2.deltaY         as double : return _yDelta                         : end property
property Mouse2.dragX          as double : return _dragDeltaX                     : end property
property Mouse2.dragY          as double : return _dragDeltaY                     : end property
property Mouse2.fromX          as double : return _dragFromX                      : end property
property Mouse2.fromY          as double : return _dragFromY                      : end property
property Mouse2.leftClicked    as boolean: return _events(Mouse2Event.LeftDown)   : end property
property Mouse2.leftReleased   as boolean: return _events(Mouse2Event.LeftUp)     : end property
property Mouse2.leftDown       as boolean: return iif(buttons and 1, true, false) : end property
property Mouse2.leftUp         as boolean: return iif(buttons and 1, false, true) : end property
property Mouse2.middleClicked  as boolean: return _events(Mouse2Event.MiddleDown) : end property
property Mouse2.middleReleased as boolean: return _events(Mouse2Event.MiddleUp)   : end property
property Mouse2.middleDown     as boolean: return iif(buttons and 4, true, false) : end property
property Mouse2.middleUp       as boolean: return iif(buttons and 4, false, true) : end property
property Mouse2.moved          as boolean: return _events(Mouse2Event.Move)       : end property
property Mouse2.rightClicked   as boolean: return _events(Mouse2Event.RightDown)  : end property
property Mouse2.rightReleased  as boolean: return _events(Mouse2Event.RightUp)    : end property
property Mouse2.rightDown      as boolean: return iif(buttons and 2, true, false) : end property
property Mouse2.rightUp        as boolean: return iif(buttons and 2, false, true) : end property
property Mouse2.wheelChanged   as boolean: return _events(Mouse2Event.WheelChange): end property
property Mouse2.wheelDelta     as _long_ : return _wheelDelta                     : end property
property Mouse2.visible        as boolean: return _isVisible                      : end property
sub Mouse2.clip()
    if clipped = 0 then
        clipped = 1
        setmouse , , , 1
    end if
end sub
sub Mouse2.unclip()
    if clipped = 1 then
        clipped = 0
        setmouse , , , 0
    end if
end sub
sub Mouse2.hide()
    if _isVisible = true then
        _isVisible = false
        setmouse , , 0
    end if
end sub
sub Mouse2.show()
    if _isVisible = false then
        _isVisible = true
        setmouse , , 1
    end if
end sub
sub Mouse2.setMode(newMode as integer)
    this._mode = newMode
end sub
sub Mouse2.update()
    dim as integer i, j
    status = getmouse(i, j, wheel, buttons, clipped)
    if status <> 0 then
        _wheelDelta = 0
        _xDelta = 0
        _yDelta = 0
        for i as integer = 0 to ubound(_events)
            _events(i) = false
        next i
    else
        x = i
        y = j
        if _mode = Mouse2Mode.Viewport then
            x = pmap(x, 2)
            y = pmap(y, 3)
        end if
        if _buttonsPrev <> buttons then
            if buttons and 1 <> _buttonsPrev and 1 then
                _events(Mouse2Event.LeftDown) = iif(buttons and 1, true, false)
                _events(Mouse2Event.LeftUp  ) = iif(buttons and 1, false, true)
            end if
            if buttons and 2 <> _buttonsPrev and 2 then
                _events(Mouse2Event.RightDown) = iif(buttons and 2, true, false)
                _events(Mouse2Event.RightUp  ) = iif(buttons and 2, false, true)
            end if
            if buttons and 4 <> _buttonsPrev and 4 then
                _events(Mouse2Event.MiddleDown) = iif(buttons and 4, true, false)
                _events(Mouse2Event.MiddleUp  ) = iif(buttons and 4, false, true)
            end if
            _buttonsPrev = buttons
        else
            _events(Mouse2Event.LeftDown)   = false
            _events(Mouse2Event.LeftUp)     = false
            _events(Mouse2Event.MiddleDown) = false
            _events(Mouse2Event.MiddleUp)   = false
            _events(Mouse2Event.RightDown)  = false
            _events(Mouse2Event.RightUp)    = false
        end if
        if _wheelPrev <> wheel then
            _wheelDelta = wheel - _wheelPrev
            _wheelPrev = wheel
            _events(Mouse2Event.WheelChange) = true
        else
            _wheelDelta = 0
            _events(Mouse2Event.WheelChange) = false
        end if
        if _xPrev <> x or _yPrev <> y then
            if _xPrev <> x then
                _xDelta = x - _xPrev
                _xPrev = x
            else
                _xDelta = 0
            end if
            if _yPrev <> y then
                _yDelta = y - _yPrev
                _yPrev = y
            else
                _yDelta = 0
            end if
            _events(Mouse2Event.Move) = true
        else
            _xDelta = 0
            _yDelta = 0
            _events(Mouse2Event.Move) = false
        end if
        if leftClicked or rightClicked then
            _dragFromX = x
            _dragFromY = y
        elseif leftDown or leftReleased _
            or rightDown or rightReleased then
            _dragDeltaX = x - _dragFromX
            _dragDeltaY = y - _dragFromY
        else
            _dragDeltaX = 0
            _dragDeltaY = 0
        end if
    end if
end sub
