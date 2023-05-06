--[[ 
--  Trackball bindings for the Elecom Deft Pro so you don't need the drivers.
--
--  Features include:
--      1. Hold-to-ball-scroll based on the Logitech Marble Mouse Lua script
--      2. Scroll wheel tilt left/right to change virtual workspaces
--      3. One-button copy-paste
--      3. Doesn't modify built-in trackpad behavior 
--]]

-- Mouse button event numbers, 0 is mouse left and 1 is mouse right
local mouseMiddle = 2 -- Wheel click
local mouseBack = 3 -- Thumb front
local mouseForward = 4 -- Thumb top
local mouse5 = 5 -- Ball left
local mouse6 = 6 -- Far right
local mouse7 = 7 -- Thumb back

-- Positive multipliers scroll the content like trackpads or touch screens
-- Negative multipliers scroll the viewport like classic mouse wheels
-- Unit will be pixels, so integers perform best
local scrollMultiplier = 3

-- Keeps track when we have deferred input events
local deferred = false

function setOverrides(e)
    overrideWheelTilt:stop()
    overrideOtherMouseDown:stop()
    overrideOtherMouseUp:stop()
    hs.eventtap.otherClick(e:location(), 0, pressedMouseButton)
    overrideOtherMouseDown:start()
    overrideOtherMouseUp:start()
    overrideWheelTilt:start()
end

overrideWheelTilt = hs.eventtap.new({hs.eventtap.event.types.scrollWheel}, function(e)
    -- Scroll wheel tilt is tracked as a horizontal scroll event on `Axis2`
    local scrollEvent = e:getProperty(hs.eventtap.event.properties['scrollWheelEventDeltaAxis2'])
    -- Trackpads use "continuous" scroll (1) and mouse wheels use "line" scroll (0)
    local continuous = e:getProperty(hs.eventtap.event.properties['scrollWheelEventIsContinuous'])
    -- print("Type: ", type, " Tilt: ", scrollEvent)

    if (continuous == 1) then
        return false
    else
        if (scrollEvent < 0) then
            -- print("Tilt left")
            -- Send `ctrl + left` to move one workspace left
            hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
            hs.eventtap.event.newKeyEvent(hs.keycodes.map.left, true):post()
            hs.eventtap.event.newKeyEvent(hs.keycodes.map.left, false):post()
            hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
            return true
        elseif (scrollEvent > 0) then
            -- print("Tilt right")
            -- Send `ctrl + right` to move one workspace right
            hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
            hs.eventtap.event.newKeyEvent(hs.keycodes.map.right, true):post()
            hs.eventtap.event.newKeyEvent(hs.keycodes.map.right, false):post()
            hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
            return true
        end
    end
end)

overrideOtherMouseDown = hs.eventtap.new({hs.eventtap.event.types.otherMouseDown}, function(e)
    local pressedMouseButton = e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber'])
    -- print("OtherMouseDown: ", pressedMouseButton)

    if (pressedMouseButton == mouse5) then
        -- send `cmd + v` for paste
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, true):post()
        hs.eventtap.event.newKeyEvent('v', true):post()
        hs.eventtap.event.newKeyEvent('v', false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, false):post()
        return true
    elseif (pressedMouseButton == mouse6) then
        -- send `cmd + c` for copy
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, true):post()
        hs.eventtap.event.newKeyEvent('c', true):post()
        hs.eventtap.event.newKeyEvent('c', false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, false):post()
        return true
    elseif (pressedMouseButton == mouse7) then
        -- send a single `return`
        hs.eventtap.event.newKeyEvent(hs.keycodes.map["return"], true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map["return"], false):post()
        return true
    elseif (pressedMouseButton == mouseBack) then
        deferred = true
        return true
    end
end)

overrideOtherMouseUp = hs.eventtap.new({hs.eventtap.event.types.otherMouseUp}, function(e)
    local pressedMouseButton = e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber'])
    -- print("OtherMouseUp: ", pressedMouseButton)
    if (deferred) then
        setOverrides(e)
        if (mouseBack == pressedMouseButton) then
            -- no button remap
            return true
        end
    end
    return false
end)

local oldmousepos = {}

dragOtherToScroll = hs.eventtap.new({hs.eventtap.event.types.otherMouseDragged}, function(e)
    local pressedMouseButton = e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber'])
    -- print ("pressed mouse " .. pressedMouseButton)
    if (pressedMouseButton == mouseBack) then
        -- print("scroll");
        deferred = false
        oldmousepos = hs.mouse.absolutePosition()
        local deltaX = e:getProperty(hs.eventtap.event.properties['mouseEventDeltaX'])
        local deltaY = e:getProperty(hs.eventtap.event.properties['mouseEventDeltaY'])
        local scrollEvent = hs.eventtap.event.newScrollEvent({deltaX * scrollMultiplier, deltaY * scrollMultiplier}, {},
            'pixel')
        -- put the mouse cursor back
        hs.mouse.absolutePosition(oldmousepos)
        return true, {scrollEvent}
    else
        return false, {}
    end
end)

overrideOtherMouseDown:start()
overrideOtherMouseUp:start()
dragOtherToScroll:start()
overrideWheelTilt:start()
