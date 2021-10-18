edit_baro = {
    elements = nil,
    alt = 0,
    pressure = 0,
    end_callback = nil,
    listeners = {},
    digits = {
        decimal = 0,
        fraction = 0
    }
}

local bg = nil
local mnu = nil
local header = nil
local footer = nil
local major = nil
local dot = nil
local minor = nil
local help_dial_outer = nil
local help_dial_inner = nil

function edit_baro.init(x, y)
    -- setup screen elements
    bg = img_add("screen_bg_edit.png", x, y, 320, 240)
    mnu = view_menu.init(x, y, {"CNCL", "", "UNIT", "QNE"})
    header = txt_add("ALTIMETER BARO", "size: 28px; color: black; font:Lato-Regular.ttf; halign: center", x, y + 40, 320, 40)
    footer = txt_add("ALT:", "size: 28px; color: black; font:Lato-Regular.ttf; halign: center", x, y + 160, 320, 40)
    major = txt_add("00", "size: 100px; color: #00ef00; font:Lato-Regular.ttf; halign: right; valign: center", x + 10, y + 70, 150, 80)
    dot = txt_add(".", "size: 100px; color: black; font:Lato-Regular.ttf; halign: center; valign: center", x + 158, y + 70, 10, 80)
    minor = txt_add("00", "size: 100px; color: DarkTurquoise; font:Lato-Regular.ttf; halign: left; valign: center", x + 165, y + 70, 100, 80)
    help_dial_outer = txt_add("DECIMAL", "size: 28px; color: white; font:Lato-Regular.ttf; halign: right; valign: center", x, y + 192, 125, 48)
    help_dial_inner = txt_add("FRACTION", "size: 28px; color: white; font:Lato-Regular.ttf; halign: left;  valign: center", x + 195, y + 192, 125, 48)
    edit_baro.elements = group_add(bg, mnu, header, footer, major, dot, minor, help_dial_outer, help_dial_inner)

    if user_prop_get(config.user.unit_pressure) == UNIT_PRESSURE.HPA then
        move(major, nil, nil, 200)
        move(dot, x + 230)
        move(minor, x + 280)
    end
    opacity(edit_baro.elements, 0)
    return edit_baro.elements
end

function edit_baro.start_edit(pressure, alt, end_callback)
    edit_baro.pressure = pressure
    edit_baro.alt = alt
    edit_baro.end_callback = end_callback

    update_altitude(pressure, alt)
    edit_baro.set_digits(pressure)

    table.insert(edit_baro.listeners, controls.add_listener("softkey-1", "PRESS", edit_baro.cancel_edit))
    table.insert(edit_baro.listeners, controls.add_listener("softkey-3", "PRESS", edit_baro.toggle_unit))
    table.insert(edit_baro.listeners, controls.add_listener("softkey-4", "PRESS", edit_baro.set_standard_pressure))
    table.insert(edit_baro.listeners, controls.add_listener("rotary-outer", "TURN", edit_baro.dial_decimal))
    table.insert(edit_baro.listeners, controls.add_listener("rotary-inner", "TURN", edit_baro.dial_fraction))
    table.insert(edit_baro.listeners, controls.add_listener("rotary-inner-button", "PRESS", edit_baro.save))

    opacity(edit_baro.elements, 1)
end

function edit_baro.cancel_edit()
    opacity(edit_baro.elements, 0)

    -- cancel and unregister all eventhandlers
    for i=1, #edit_baro.listeners do
        edit_baro.listeners[i]()
        edit_baro.listeners[i] = nil
    end
    edit_baro.listeners = {}

    if edit_baro.end_callback then
        edit_baro.end_callback()
    end
end

function edit_baro.save()
    local press_inhg = 0
    local press_hpa = 0
    local pressure = get_pressure_from_digits(edit_baro.digits.decimal, edit_baro.digits.fraction)

    if user_prop_get(config.user.unit_pressure) == UNIT_PRESSURE.INHG then
        press_inhg = pressure
        press_hpa = get_inhg_in_hpa(press_inhg)
    else
        press_hpa = pressure
        press_inhg = get_hpa_in_inhg(press_hpa)
    end
    xpl_dataref_write("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot", "FLOAT", press_inhg)
    fsx_variable_write("KOHLSMAN SETTING MB", "Milibars", press_hpa)
    fs2020_variable_write("KOHLSMAN SETTING MB", "Milibars", press_hpa)
    edit_baro.cancel_edit()
end

function edit_baro.set_digits(pressure)
    edit_baro.digits.decimal = (pressure * 100 - (pressure * 100) % 100) / 100
    edit_baro.digits.fraction = (pressure * 100) % 100
    txt_set(major, string.format("%g", edit_baro.digits.decimal))
    txt_set(minor, string.format("%g", edit_baro.digits.fraction))
end

function update_altitude(pressure, altitude)
    local alt = 0

    if user_prop_get(config.user.unit_pressure) == UNIT_PRESSURE.INHG then
        alt = get_pressure_altitude_inhg(pressure, altitude)
    else
        alt = get_pressure_altitude_hpa(pressure, altitude)
    end

    if persist_get(config.persist.unit_alt) == UNITS.IMPERIAL then
        txt_set(footer, string.format("ALT: %.0f ft", alt))
    else
        txt_set(footer, string.format("ALT: %.0f m", get_feet_in_m(alt)))
    end
end

function edit_baro.dial_decimal(direction)
    local val = edit_baro.digits.decimal + direction
    -- var_cap doesn't seem to work with floats
    if val < 0 then val = 0 end
    if val > 1065 then val = 1065 end
    edit_baro.digits.decimal = val
    txt_set(major, string.format("%g", edit_baro.digits.decimal))
    update_altitude(get_pressure_from_digits(), edit_baro.alt)
end

function edit_baro.dial_fraction(direction)
    local val = edit_baro.digits.fraction + direction
    if val < 0 then val = 0 end
    if val > 99 then val = 99 end
    edit_baro.digits.fraction = val
    txt_set(minor, string.format("%g", edit_baro.digits.fraction))
    update_altitude(get_pressure_from_digits(), edit_baro.alt)
end

function edit_baro.set_standard_pressure()
    if user_prop_get(config.user.unit_pressure) == UNIT_PRESSURE.INHG then
        edit_baro.set_digits(STANDARD_PRESSURE_INHG)
    else
        edit_baro.set_digits(STANDARD_PRESSURE_HPA)
    end
end

function edit_baro.toggle_unit()
    if persist_get(config.persist.unit_alt) == UNITS.METRIC then
        persist_put(config.persist.unit_alt, UNITS.IMPERIAL)
    else
        persist_put(config.persist.unit_alt, UNITS.METRIC)
    end
    update_altitude(get_pressure_from_digits(), edit_baro.alt)
end

function get_pressure_from_digits()
    return edit_baro.digits.decimal + edit_baro.digits.fraction / 100
end

return edt_baro