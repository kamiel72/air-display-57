function to_bcd16(frequency)

    local bcd = 0
    
    for i = 0, 3 do
        bcd = bcd + (math.floor(frequency % 10) << (i * 4))
        frequency = frequency / 10
    end
    
    return bcd
    
end

function get_feet_in_m(feet)
    return feet * 0.3048 -- 1 foot = 0.3048 m
end

function get_inhg_in_hpa(inhg)
    return inhg * 33.8639 -- 1 inHg = 33.8639 hPa
end

function get_hpa_in_inhg(hpa)
    return hpa / 33.8639
end

function get_pressure_altitude_inhg(pressure_inhg, altitude_ft)
    -- Returns altitude in feet
    return altitude_ft + 1000 * (STANDARD_PRESSURE_INHG - pressure_inhg)
end

function get_pressure_altitude_hpa(pressure_hpa, altitude_ft)
    -- Returns altitude in feet
    return altitude_ft + 30 * (STANDARD_PRESSURE_HPA - pressure_hpa)
end