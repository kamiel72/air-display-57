screen_main = {
    elements = nil
}

local alt = nil
local mnu = nil
local com = nil
local xpdr = nil
local bg = nil

function screen_main.init(x, y)
    local hasCom = user_prop_get(config.user.display_com)
    local hasAlt = user_prop_get(config.user.display_alt)
    local hasXpdr = user_prop_get(config.user.display_xpdr)

    if hasCom and hasAlt and hasXpdr then
        -- Show all views
        mnu = view_menu.init(x,y, {"","CHN","XPDR","BARO"})
        com = view_com.init(x, y + 30, "M")
        alt = altimeter.init(x, y + 135, "S")
        xpdr = view_transponder.init(x + 200, y + 135, "S", "DARK")
        screen_main.elements = group_add(mnu, alt, com, xpdr)

    elseif hasCom and not hasAlt and not hasXpdr then
        -- Only show COM
        mnu = view_menu.init(x,y, {"","CHN","",""})
        com = view_com.init(x, y + 30, "L")
        screen_main.elements = group_add(mnu, com)

    elseif not hasCom and hasAlt and not hasXpdr then
        -- Only show altimeter
        mnu = view_menu.init(x,y, {"","","UNIT","QNE"})
        alt = altimeter.init(x, y + 30, "L")
        screen_main.elements = group_add(mnu, alt)

    elseif not hasCom and not hasAlt and hasXpdr then
        -- Only show transponder
        mnu = view_menu.init(x,y, {"","MDE","IDNT",""})
        xpdr = view_transponder.init(x, y + 30, "L", "DARK")
        screen_main.elements = group_add(mnu, xpdr)

    elseif hasCom and not hasAlt and hasXpdr then
        -- Show COM and transponder
        bg = img_add("screen_bg_half.png", x, y, 320, 240)
        mnu = view_menu.init(x,y, {"","CHN","XPDR",""})
        com = view_com.init(x, y + 30, "M")
        xpdr = view_transponder.init(x, y + 135, "M", "DARK")
        screen_main.elements = group_add(mnu, com, xpdr, bg)

    elseif hasCom and hasAlt and not hasXpdr then
        -- Show COM and altimeter
        bg = img_add("screen_bg_half.png", x, y, 320, 240)
        mnu = view_menu.init(x,y, {"","CHN","","BARO"})
        com = view_com.init(x, y + 30, "M")
        alt = altimeter.init(x, y + 135, "M")
        screen_main.elements = group_add(mnu, com, alt, bg)

    elseif not hasCom and hasAlt and hasXpdr then
        -- Show transponder and altimeter
        bg = img_add("screen_bg_half.png", x, y, 320, 240)
        mnu = view_menu.init(x,y, {"","MDE","IDNT","BARO"})
        xpdr = view_transponder.init(x, y + 30, "M", "LIGHT")
        alt = altimeter.init(x, y + 135, "M")
        screen_main.elements = group_add(mnu, xpdr, alt, bg)
    end

    -- init editors
    edit_com.init(x,y)
    edit_xpdr.init(x,y)
    edit_baro.init(x,y)

    -- register event callbacks
    register_events(hasCom, hasAlt, hasXpdr)

    return screen_main.elements
end

function register_events(hasCom, hasAlt, hasXpdr)

    if hasCom and hasAlt and hasXpdr then
        -- All views
        controls.add_listener("softkey-2", "PRESS", view_com.start_edit)
        controls.add_listener("softkey-3", "PRESS", view_transponder.start_edit)
        controls.add_listener("softkey-4", "PRESS", altimeter.start_edit)
        controls.add_listener("rotary-inner-button", "PRESS", view_com.toggle_channel)

    elseif hasCom and not hasAlt and not hasXpdr then
        -- Only COM
        controls.add_listener("softkey-2", "PRESS", view_com.start_edit)
        controls.add_listener("rotary-inner-button", "PRESS", view_com.toggle_channel)

    elseif not hasCom and hasAlt and not hasXpdr then
        -- Only altimeter
        controls.add_listener("rotary-inner", "TURN", altimeter.start_edit)
        controls.add_listener("rotary-outer", "TURN", altimeter.start_edit)
        controls.add_listener("softkey-3", "PRESS", altimeter.toggle_units)
        controls.add_listener("softkey-4", "PRESS", altimeter.set_standard_pressure)

    elseif not hasCom and not hasAlt and hasXpdr then
        -- Only transponder
        controls.add_listener("rotary-inner", "TURN", view_transponder.start_edit)
        controls.add_listener("rotary-outer", "TURN", view_transponder.start_edit)
        controls.add_listener("softkey-2", "PRESS", view_transponder.toggle_mode)
        controls.add_listener("softkey-3", "PRESS", view_transponder.ident)

    elseif hasCom and not hasAlt and hasXpdr then
        -- Show COM and transponder
        controls.add_listener("softkey-2", "PRESS", view_com.start_edit)
        controls.add_listener("softkey-3", "PRESS", view_transponder.start_edit)
        controls.add_listener("rotary-inner-button", "PRESS", view_com.toggle_channel)

    elseif hasCom and hasAlt and not hasXpdr then
        -- COM and altimeter
        controls.add_listener("softkey-2", "PRESS", view_com.start_edit)
        controls.add_listener("softkey-4", "PRESS", altimeter.start_edit)
        controls.add_listener("rotary-inner-button", "PRESS", view_com.toggle_channel)

    elseif not hasCom and hasAlt and hasXpdr then
        -- transponder and altimeter
        controls.add_listener("softkey-2", "PRESS", view_transponder.toggle_mode)
        controls.add_listener("softkey-2", "LONG_PRESS", view_transponder.toggle_mode)
        controls.add_listener("softkey-3", "PRESS", view_transponder.ident)
        controls.add_listener("softkey-4", "PRESS", altimeter.start_edit)
        controls.add_listener("rotary-inner", "TURN", view_transponder.start_edit)
        controls.add_listener("rotary-outer", "TURN", view_transponder.start_edit)
    end

end

function screen_main.update_alt(altitude, pressure)
    altimeter.update(altitude, pressure)
end

function screen_main.update_com(com1, com1_stby, com1_tx, com1_rx)
    view_com.update(com1, com1_stby, com1_tx, com1_rx)
end

function screen_main.update_xpdr(mode, code, ident, reply, alt, ground)
    view_transponder.update(mode, code, ident, reply, alt, ground)
end

return screen_main