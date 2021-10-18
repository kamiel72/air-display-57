edit_com = {
    elements = nil,
    listeners = {},
    end_callback = nil,
    mhz_val = 118,
    khz_val = 0
}

local bg = nil
local mnu = nil
local header = nil
local mhz = nil
local dot = nil
local khz = nil
local help_dial_outer = nil
local help_dial_inner = nil

function edit_com.init(x, y)
    -- setup screen elements
    bg = img_add("screen_bg_edit.png", x, y, 320, 240)
    mnu = view_menu.init(x, y, {"CNCL", "", "", ""})
    header = txt_add("SBY COM CHANNEL", "size: 28px; color: black; font:Lato-Regular.ttf; halign: center", x, y + 40, 320, 40)
    mhz = txt_add("118", "size: 100px; color: #00ef00; font:Lato-Regular.ttf; halign: right; valign: center", x + 10, y + 70, 150, 80)
    dot = txt_add(".", "size: 100px; color: black; font:Lato-Regular.ttf; halign: center; valign: center", x + 158, y + 70, 10, 80)
    khz = txt_add("000", "size: 100px; color: DarkTurquoise; font:Lato-Regular.ttf; halign: right; valign: center", x + 160, y + 70, 150, 80)
    help_dial_outer = txt_add("MHz", "size: 28px; color: white; font:Lato-Regular.ttf; halign: right; valign: center", x, y + 192, 125, 48)
    help_dial_inner = txt_add("kHz", "size: 28px; color: white; font:Lato-Regular.ttf; halign: left;  valign: center", x + 195, y + 192, 125, 48)
    edit_com.elements = group_add(bg, mnu, header, mhz, dot, khz, help_dial_outer, help_dial_inner)
    opacity(edit_com.elements, 0)
    return edit_com.elements
end

function edit_com.start_edit(stby_freq, end_callback)
    -- Start com edit
    edit_com.khz_val = stby_freq % 100
    edit_com.mhz_val = (stby_freq - stby_freq % 100) / 100
    edit_com.end_callback = end_callback

    txt_set(mhz, string.format("%d", edit_com.mhz_val))
    txt_set(khz, string.format("%03d", edit_com.khz_val))

    -- register listeners for buttons and encoders
    table.insert(edit_com.listeners, controls.add_listener("softkey-1", "PRESS", edit_com.cancel_edit))
    table.insert(edit_com.listeners, controls.add_listener("rotary-outer", "TURN", edit_com.dial_mhz))
    table.insert(edit_com.listeners, controls.add_listener("rotary-inner", "TURN", edit_com.dial_khz))
    table.insert(edit_com.listeners, controls.add_listener("rotary-inner-button", "PRESS", edit_com.save))

    opacity(edit_com.elements, 1)
end

function edit_com.cancel_edit()
    opacity(edit_com.elements, 0)

        -- cancel and unregister all eventhandlers
    for i=1, #edit_com.listeners do
        edit_com.listeners[i]()
        edit_com.listeners[i] = nil
    end
    edit_com.listeners = {}

    if edit_com.end_callback then
        edit_com.end_callback()
    end
end

function edit_com.save()
    -- save data to SIM and cancel edit
    freq = (edit_com.mhz_val * 1000 + edit_com.khz_val) / 10
    xpl_dataref_write("sim/cockpit2/radios/actuators/com1_standby_frequency_hz", "INT", freq)
    fs2020_event("COM_STBY_RADIO_SET", freq)
    fsx_event("COM_STBY_RADIO_SET", freq)

    edit_com.cancel_edit()
end

function edit_com.dial_mhz(direction)
    if direction == 1 then
        edit_com.mhz_val = edit_com.mhz_val + 1
    else
        edit_com.mhz_val = edit_com.mhz_val - 1
    end
    edit_com.mhz_val = var_cap(edit_com.mhz_val, 118, 136)
    txt_set(mhz, string.format("%03d", edit_com.mhz_val))
end

function get_step(list, item)
    -- for 25kHz step is always 25
    if user_prop_get(config.user.com_spacing) == "25 kHz" then
        return 25
    end

    -- for 8.33 kHz we look up the spacing
    for i=1,#list do
        if list[i] == item then 
            return 15 
        end
    end
    return 5
end

function edit_com.dial_khz(direction)
    pos = edit_com.khz_val % 100
    if direction == 1 then
        edit_com.khz_val = edit_com.khz_val + get_step({ 15, 40, 65, 90 }, pos)
    else
        edit_com.khz_val = edit_com.khz_val - get_step({ 5, 30, 55, 80}, pos)
    end

    if user_prop_get(config.user.com_spacing) == "8.33 kHz" then
        edit_com.khz_val = var_cap(edit_com.khz_val, 5, 990)
    else
        edit_com.khz_val = var_cap(edit_com.khz_val, 0, 975)
    end

    txt_set(khz, string.format("%03d", edit_com.khz_val))
end

return edit_com