edit_xpdr = {
    elements = nil,
    listeners = {},
    x =0,
    code = 0,
    mode = nil,
    end_callback = nil,
    pointer = 2,
    digit_elems = {},
    digits = {0, 0, 0, 0}
}

local bg = nil
local mnu = nil
local header = nil
local footer = nil
local cursor = nil
local help_dial_outer = nil
local help_dial_inner = nil

function format_nr(i)
    return string.format("%d", math.abs(i))
end

function add_digit(idx, x, y)
    local w = 50
    local h = 75
    local spinner = running_txt_add_ver(x + (idx-1)*w, y - h, 3, w, h, format_nr, "size: 110px; color: DarkTurquoise; font:Lato-Regular.ttf; halign: center; valign: center")
    local fixed = txt_add("0", "size: 110px; color: black; font:Lato-Regular.ttf; halign: center; valign: center", x + (idx-1) * w, y, w, h)
    running_txt_move_carot(spinner, 0)
    viewport_rect(spinner, x + (idx-1)*w, y, w, h)
    edit_xpdr.digit_elems[idx] = { spinner, fixed }
    group_obj_add(edit_xpdr.elements, spinner)
    group_obj_add(edit_xpdr.elements, fixed)
    visible(spinner, false)
end

function edit_xpdr.init(x, y)
    edit_xpdr.x = x;

    -- setup screen elements
    bg = img_add("screen_bg_edit.png", x, y, 320, 240)
    mnu = view_menu.init(x, y, {"CNCL", "VFR", "MDE", "IDNT"})
    cursor = img_add("cursor.png", x, y + 150, 50, 10)
    header = txt_add("XPDR SQUAWK", "size: 28px; color: black; font:Lato-Regular.ttf; halign: center", x, y + 40, 320, 40)
    footer = txt_add("MODE:", "size: 28px; color: black; font:Lato-Regular.ttf; halign: center", x, y + 160, 320, 40)
    help_dial_outer = txt_add("CURSOR", "size: 28px; color: white; font:Lato-Regular.ttf; halign: right; valign: center", x, y + 192, 125, 48)
    help_dial_inner = txt_add("DIGIT", "size: 28px; color: white; font:Lato-Regular.ttf; halign: left;  valign: center", x + 195, y + 192, 125, 48)
    edit_xpdr.elements = group_add(bg, mnu, cursor, header, footer, help_dial_outer, help_dial_inner)
    
    add_digit(1, x + 60, y + 70)
    add_digit(2, x + 60, y + 70)
    add_digit(3, x + 60, y + 70)
    add_digit(4, x + 60, y + 70)
    digits = group_add()

    edit_xpdr.move_cursor(-1)

    opacity(edit_xpdr.elements, 0)
    return edit_xpdr.elements
end

function update_digit(idx, val)
    edit_xpdr.digits[idx] = val
    txt_set(edit_xpdr.digit_elems[idx][2], tostring(val))
    running_txt_move_carot(edit_xpdr.digit_elems[idx][1], val)
end

function edit_xpdr.set_digits(code)
    local str_code = string.format("%04d", code)
    for i=1, 4 do
        local nr = tonumber(string.sub(str_code, i, i))
        edit_xpdr.digits[i] = nr
        running_txt_move_carot(edit_xpdr.digit_elems[i][1], nr)
        txt_set(edit_xpdr.digit_elems[i][2], tostring(nr))
    end
end

function edit_xpdr.start_edit(mode, code, end_callback)

    -- Set values to edit
    edit_xpdr.code = code
    edit_xpdr.mode = mode
    edit_xpdr.end_callback = end_callback
    if mode then
        txt_set(footer, "MODE: " .. mode)
    end
    edit_xpdr.set_digits(code)

    -- register listeners for buttons and encoders
    table.insert(edit_xpdr.listeners, controls.add_listener("softkey-1", "PRESS", edit_xpdr.cancel_edit))
    table.insert(edit_xpdr.listeners, controls.add_listener("softkey-2", "PRESS", edit_xpdr.select_vfr_sqwuak))
    table.insert(edit_xpdr.listeners, controls.add_listener("softkey-3", "PRESS", edit_xpdr.toggle_mode))
    table.insert(edit_xpdr.listeners, controls.add_listener("softkey-3", "LONG_PRESS", edit_xpdr.set_mode_on))
    table.insert(edit_xpdr.listeners, controls.add_listener("softkey-4", "PRESS", edit_xpdr.cancel_edit))
    table.insert(edit_xpdr.listeners, controls.add_listener("rotary-outer", "TURN", edit_xpdr.move_cursor))
    table.insert(edit_xpdr.listeners, controls.add_listener("rotary-inner", "TURN", edit_xpdr.change_digit))
    table.insert(edit_xpdr.listeners, controls.add_listener("rotary-inner-button", "PRESS", edit_xpdr.save))
    opacity(edit_xpdr.elements, 1)
end

function edit_xpdr.cancel_edit()
    opacity(edit_xpdr.elements, 0)
    
    -- cancel and unregister all eventhandlers
    for i=1, #edit_xpdr.listeners do
        edit_xpdr.listeners[i]()
        edit_xpdr.listeners[i] = nil
    end
    edit_xpdr.listeners = {}

    if edit_xpdr.end_callback then
        edit_xpdr.end_callback()
    end
end

function edit_xpdr.move_cursor(direction)

    if (edit_xpdr.pointer + direction) >= 1 and edit_xpdr.pointer + direction <= 4 then
        -- hide selected digit spinner
        -- would be easier if we could just change the text color
        visible(edit_xpdr.digit_elems[edit_xpdr.pointer][1], false)
        visible(edit_xpdr.digit_elems[edit_xpdr.pointer][2], true)

        -- set new position
        edit_xpdr.pointer = edit_xpdr.pointer + direction
        var_cap(edit_xpdr.pointer, 1, 4)
        
        -- Show selected digit spinner
        visible(edit_xpdr.digit_elems[edit_xpdr.pointer][1], true)
        visible(edit_xpdr.digit_elems[edit_xpdr.pointer][2], false)

        -- Move cursor
        move(cursor, edit_xpdr.x + 60 + (edit_xpdr.pointer - 1) * 50)
    end 

end

function edit_xpdr.change_digit(direction)
    local val = edit_xpdr.digits[edit_xpdr.pointer]
    if val + direction >=0 and val + direction <= 7 then
        val = val + direction
        running_txt_move_carot(edit_xpdr.digit_elems[edit_xpdr.pointer][1], val)
        txt_set(edit_xpdr.digit_elems[edit_xpdr.pointer][2], tostring(val))
        edit_xpdr.digits[edit_xpdr.pointer] = val
    end
end

function edit_xpdr.save()
    -- reassemble individual digits
    local code = 0;
    for i=1, 4 do
        code = code + (10 ^ (4-i)) * edit_xpdr.digits[i]
    end

    --save
    edit_xpdr.code = code
    save(code)
    edit_xpdr.cancel_edit()
end

function save(code)
    -- send code to sim
    xpl_dataref_write("sim/cockpit/radios/transponder_code", "INT", code)
    fsx_event("XPNDR_SET", to_bcd16(code))
    fs2020_event("XPNDR_SET", to_bcd16(code))
end

function edit_xpdr.select_vfr_sqwuak()
    -- set VFR squawk code
    edit_xpdr.set_digits(user_prop_get(config.user.default_vfr_squawk))
end

function edit_xpdr.toggle_mode()
    if edit_xpdr.mode == "ALT" then
        edit_xpdr.mode = "STBY"
        txt_set(footer, "MODE: STBY")
        xpl_dataref_write("sim/cockpit/radios/transponder_mode","INT", XPL_XPDR_MODE.STBY)
        fs2020_variable_write("TRANSPONDER STATE:1", "Enum", FS_XPDR_MODE.STBY)
        fsx_variable_write("TRANSPONDER STATE:1", "Enum", FS_XPDR_MODE.STBY)
    else
        edit_xpdr.mode = "ALT"
        txt_set(footer, "MODE: ALT")
        xpl_dataref_write("sim/cockpit/radios/transponder_mode","INT", XPL_XPDR_MODE.ALT)
        fs2020_variable_write("TRANSPONDER STATE:1", "Enum", FS_XPDR_MODE.ALT)
        fsx_variable_write("TRANSPONDER STATE:1", "Enum", FS_XPDR_MODE.ALT)
    end
end

function edit_xpdr.ident()
    -- Send Ident
    edit_xpdr.save()
    xpl_command("sim/transponder/transponder_ident")
    fsx_event("H:TransponderIDT")
    fs2020_event("H:TransponderIDT")
end

function edit_xpdr.set_mode_on()
    -- Set transponder mode to ON
    edit_xpdr.mode = "ON"
    txt_set(footer, "MODE: ON")
    xpl_dataref_write("sim/cockpit/radios/transponder_mode","INT", XPL_XPDR_MODE.ON)
    fs2020_variable_write("TRANSPONDER STATE:1", "Enum", FS_XPDR_MODE.ON)
    fsx_variable_write("TRANSPONDER STATE:1", "Enum", FS_XPDR_MODE.ON)
end

return edit_xpdr