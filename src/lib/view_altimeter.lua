altimeter = {
    elements = nil,
    editing = false,
    alt = 0,
    pressure = 0
}

local D = {
    L = {
        width = 320,
        height = 210,
        char_size_l = 85,
        char_size_m = 40,
        char_size_s = 24,
        char_width = 40,
        char_height = 70,
        char_minor_width = 90,
        ruler_img = "ruler-large.png",
        ruler_height = 105
    },
    M = {
        width = 320,
        height = 100,
        char_size_l = 60,
        char_size_m = 26,
        char_size_s = 24,
        char_width = 32,
        char_height = 50,
        char_minor_width = 65,
        ruler_img = "ruler-small.png",
        ruler_height = 50
    },
    S = {
        width = 200,
        height = 100,
        char_size_l = 60,
        char_size_m = 26,
        char_size_s = 24,
        char_width = 28,
        char_height = 50,
        char_minor_width = 70,
        ruler_img = "ruler-small.png",
        ruler_height = 50
    }
}

local baro = nil
local unit_alt = nil
local alt_ruler = nil
local alt_minor_digits_scroll = nil
local alt_hundreds_digits_scroll = nil
local alt_thousands_digits_scroll = nil
local alt_tenthousands_digits_scroll = nil

function minor_nr_format(i)
    if i == 0 then
        return "00"
    elseif i > 0 then
        return string.format("%02d", (10 * i) % 100)
    else
        return string.format("%02d", (10 * (0-i)) % 100)
    end
end

function major_nr_format(i)
    if i == 0 then
        return " "
    elseif math.abs(i) >= 10 then
        return string.format("%d", math.abs(i)-10)
    else
        return string.format("%d", math.abs(i))
    end
end

function ruler_format(i)
    return string.format("%d", i * -20)
end

function make_rolling_nr(x, y, width, height, font_size)
    refId = running_txt_add_ver(x, y - height - 2, 3, width, height, major_nr_format, 
        string.format("size:%dpx; font:Lato-Regular.ttf; color:white; halign:center; valign: center", font_size))
    viewport_rect(refId, x, y, width, height)
    running_txt_move_carot(refId, 0)

    return refId
end

function altimeter.init(x, y, size)
    -- Arrow background
    arrow = canvas_add(x, y, D[size].width, D[size].height);
    canvas_draw(arrow, function()
        _rect(0, 0, D[size].width, D[size].height)
        _fill("black")
        local x1 = D[size].width - D[size].char_minor_width - 4
        local x2 = D[size].width - D[size].char_minor_width - 3*D[size].char_width
        local y1 = D[size].height/2 - D[size].char_height/2
        local y2 = D[size].height/2 + D[size].char_height/2
        _move_to(x1, 0)
        _line_to(x1, y1)
        _line_to(x2, y1)
        _line_to(D[size].width - D[size].char_width*3.75 - D[size].char_minor_width, D[size].height/2)
        _line_to(x2, y2)
        _line_to(x1, y2)
        _line_to(x1, D[size].height)
        if size == "S" then
            _move_to(D[size].width - 2, 0)
            _line_to(D[size].width - 2, D[size].height)
        end
        _stroke("white", 4)

    end)

    altimeter.elements = group_add(arrow)

    -- Barometric pressure
    baro = txt_add(" ", string.format("size:%dpx; font:Lato-Regular.ttf; color: #00ffff; valign: bottom; halign:right", 
        D[size].char_size_m), x, y + D[size].height/2 + D[size].char_height/2, 
        D[size].width - D[size].char_minor_width - 10, 
        D[size].height/2 - D[size].char_height/2)
    group_obj_add(altimeter.elements, baro)

    -- Altitude units m or ft
    unit_alt = txt_add(" ", string.format("size:%dpx; font:Lato-Regular.ttf; color: #ffffff; valign: center; halign:center", 
        D[size].char_size_m), x + D[size].width - D[size].char_minor_width - D[size].char_width*3, y, 
        D[size].char_width*3, 
        D[size].height/2 - D[size].char_height/2)
    group_obj_add(altimeter.elements, unit_alt)

    -- scrolling altitude 10s
    alt_minor_digits_scroll = running_txt_add_ver(x + D[size].width - D[size].char_minor_width, 
        y  + D[size].height/2 - D[size].char_height*2.5 - 2, 5, D[size].char_minor_width, D[size].char_height, minor_nr_format, 
        string.format("size:%dpx; font:Lato-Regular.ttf; color:white; halign:left; valign: center;", D[size].char_size_l))
    viewport_rect(alt_minor_digits_scroll, x + D[size].width - D[size].char_minor_width, y, D[size].char_minor_width, D[size].height)
    running_txt_move_carot(alt_minor_digits_scroll, 0)
    group_obj_add(altimeter.elements, alt_minor_digits_scroll)

    -- scrolling altitude 100s
    x1 = x + D[size].width - D[size].char_width - D[size].char_minor_width
    y1 = y + D[size].height/2 - D[size].char_height/2
    w1 = D[size].char_width
    h1 = D[size].char_height
    f1 = D[size].char_size_l
    alt_hundreds_digits_scroll = make_rolling_nr(x1, y1, w1, h1, f1)
    group_obj_add(altimeter.elements, alt_hundreds_digits_scroll)

    -- scrolling altitude 1000s
    x1 = x + D[size].width - 2*D[size].char_width - D[size].char_minor_width
    alt_thousands_digits_scroll = make_rolling_nr(x1, y1, w1, h1, f1)
    group_obj_add(altimeter.elements, alt_thousands_digits_scroll)

    -- scrolling altitude 10000s
    x1 = x + D[size].width - 3*D[size].char_width - D[size].char_minor_width
    alt_tenthousands_digits_scroll = make_rolling_nr(x1, y1, w1, h1, f1)
    group_obj_add(altimeter.elements, alt_tenthousands_digits_scroll)

    -- negative sign
    neg = txt_add("-", string.format("size:%dpx; font:Lato-Regular.ttf; color:white; halign:center; valign: center", f1), 
        x1, y1 - 2, w1, h1)
    visible(neg, false)
    group_obj_add(altimeter.elements, neg)

    -- Ruler
    alt_ruler = running_img_add_ver(D[size].ruler_img, x, y, 3, 15, D[size].ruler_height)
    running_txt_move_carot(alt_ruler, 0)
    viewport_rect(alt_ruler, x, y, D[size].width, D[size].height)
    group_obj_add(altimeter.elements, alt_ruler)

    if size ~= "S" then
        alt_ruler_labels = running_txt_add_ver(x + 20, y - D[size].height/4, 3, D[size].width/3, D[size].height/2, ruler_format, string.format("size:%dpx; font:Lato-Regular.ttf; color:white; halign: left; valign: center", D[size].char_size_s))
        running_txt_move_carot(alt_ruler_labels, 0)
        viewport_rect(alt_ruler_labels, x, y, D[size].width, D[size].height)
        group_obj_add(altimeter.elements, alt_ruler_labels)
    end
    
    return altimeter.elements
end

function getAltitude(alt)
    -- returns altitude in feet or meters depending on the user config
    if persist_get(config.persist.unit_alt) == UNITS.METRIC then
        return get_feet_in_m(alt)
    else
        return alt
    end
end

function getPressure(pressure)
    -- return pressure in hPa or inHg depending on the user config
    if user_prop_get(config.user.unit_pressure) == UNIT_PRESSURE.INHG then
        -- Pressure in inHg
        return string.format("%02.02f", pressure)
    else
        -- pressure in hPa
        return string.format("%04.01f", get_inhg_in_hpa(pressure))
    end
end

function getMinorDigit(altitude)
    return altitude / 10
end

function getMajorDigit(val, base)
    -- we calculate without sign to make it a little easier to do calculations
    local sign = val < 0 and -1 or 1
    local val = math.abs(val)

    if base > val then
        if val >= (base / 10 - 1) * 10 then
            -- we are about to need to roll over to 1 
            return ((val % 100) - 90) / 10 * sign
        else
            -- roll over is far away
            return 0
        end
    else
        local digit = 0

        -- first get rid of larger digits
        val = val % (base*10)
        
        -- this is the digit we want to display
        digit = (val - val % base) / base

        -- used for fancy number animation.
        if val % base >= (base / 10 - 1) * 10 then
            return (10 + digit + ((val % 100) - 90) / 10) * sign
        end
        return (10 + digit) * sign
    end
end

function altimeter.update(altitude, pressure)
    -- unrealistic wide altitude cap (in feet)
    altitude = var_cap(altitude, -990, 99900)

    altimeter.alt = altitude
    altimeter.pressure = pressure

    txt_set(baro, getPressure(pressure))
    txt_set(unit_alt, persist_get(config.persist.unit_alt) == UNITS.METRIC and "m" or "ft")
    altitude = getAltitude(altitude)
    running_txt_move_carot(alt_minor_digits_scroll, -1 * getMinorDigit(altitude))
    running_txt_move_carot(alt_hundreds_digits_scroll, -1 * getMajorDigit(altitude, 100))
    running_txt_move_carot(alt_thousands_digits_scroll, -1 * getMajorDigit(altitude, 1000))
    running_txt_move_carot(alt_tenthousands_digits_scroll, -1 * getMajorDigit(altitude, 10000))
    running_txt_move_carot(alt_ruler, -1 * (altitude / 20))
    visible(neg, altitude < 0)
    if alt_ruler_labels then
        running_txt_move_carot(alt_ruler_labels, -1 * (altitude / 20))
    end
end

function altimeter.start_edit()
    if not altimeter.editing then
        altimeter.editing = true
        edit_baro.start_edit(altimeter.pressure, altimeter.alt, altimeter.end_edit)
    end
end

function altimeter.end_edit()
    altimeter.editing = false
end

function altimeter.toggle_units()
    if not altimeter.editing then
        if persist_get(config.persist.unit_alt) == UNITS.METRIC then
            persist_put(config.persist.unit_alt, UNITS.IMPERIAL)
            txt_set(unit_alt, "ft")
        else
            persist_put(config.persist.unit_alt, UNITS.METRIC)
            txt_set(unit_alt, "m")
        end
    end
end

function altimeter.set_standard_pressure()
    if not altimeter.editing then
        xpl_dataref_write("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot", "FLOAT", STANDARD_PRESSURE_INHG)
        fsx_variable_write("KOHLSMAN SETTING MB", "Milibars", STANDARD_PRESSURE_HPA)
        fs2020_variable_write("KOHLSMAN SETTING MB", "Milibars", STANDARD_PRESSURE_HPA)
    end
end

return altimeter