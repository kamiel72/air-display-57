controls = {
    listeners = {}
}

function controls.init(x, y)
    img_add("rotary.png", x + 104, y + 250, 112, 112)
    new_softkey("softkey-1", x + 11, y - 95, 58, 49)
    new_softkey("softkey-2", x + 88, y - 102, 62, 56)
    new_softkey("softkey-3", x + 169, y - 102, 62, 56)
    new_softkey("softkey-4", x + 251, y - 95, 58, 49)
    new_dial("rotary-outer", x + 104, y + 250, 112, 112)
    new_dial("rotary-inner", x + 120, y + 266, 80, 80, true)
end

function new_softkey(id, x, y, w, h)
    local timer = nil
    local filename = id .. ".png"

    controls.listeners[id] = {}

    function key_down()
        timer = os.time()
    end

    function key_up()
        local event = nil
        if os.time() - timer >= 2 then
            -- long press
            event = "LONG_PRESS"
        else
            -- short press
            event = "PRESS"
        end

        controls.fire_event(id, event)
    end

    button_add(filename, filename, x, y, w, h, key_down, key_up)
    hw_button_add(id, key_down, key_up)
end

function new_dial(id, x, y, w, h, with_button)

    controls.listeners[id] = {}

    function key_down()
        -- not used
    end

    function key_up()
        controls.fire_event(id .. "-button", "PRESS")
    end

    function rotate(direction)
        controls.fire_event(id, "TURN", direction)
    end

    local dial = nil

    if with_button then
        dial = dial_add(nil, x, y, w, h, rotate, key_down, key_up)
        hw_button_add(id .. "-button", key_down, key_up)
    else
        dial = dial_add(nil, x, y, w, h, rotate)
    end
    -- deterrmines number of steps when using the scroll wheel
    mouse_setting(dial, "SCROLL_TICK", 50)

    hw_dial_add(id, rotate)
end

function controls.add_listener(id, event, callback)
    -- Init event tables
    if not controls.listeners[id] then
        controls.listeners[id] = { [event] = {} }
    elseif not controls.listeners[id][event] then
        controls.listeners[id][event] = {}
    end

    -- Add listener to list
    local idx = #controls.listeners[id][event] + 1
    controls.listeners[id][event][idx] = callback

    -- return unregister function
    return function()
        controls.listeners[id][event][idx] = nil
    end
end

function controls.fire_event(target, event, dir)
    -- let all listeners know an event has triggered
    if controls.listeners[target] and controls.listeners[target][event] then
        for i=1, #controls.listeners[target][event] do
            -- call all listeners
            controls.listeners[target][event][i](dir)
        end
    end
end

return controls