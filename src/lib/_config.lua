-- Constants
STANDARD_PRESSURE_INHG = 29.92
STANDARD_PRESSURE_HPA = 1013.25

UNITS = {
    METRIC = 1,
    IMPERIAL = 2
}
UNIT_PRESSURE = {
    HPA = "hPa",
    INHG = "inHg"
}
-- Transponder modes
XPL_XPDR_MODE = {
    OFF = 0,
    STBY = 1,
    ON = 2,
    ALT = 3,
    TST = 4
}
FS_XPDR_MODE = {
    OFF = 0,
    STBY = 1,
    TST = 2,
    ON = 3,
    ALT = 4,
    GND = 4 -- Air display shows GND as a state not as a mode 
}

config = {
    -- User variables
    user = {
        display_alt = user_prop_add_boolean("Show altitude", true, ""),
        display_xpdr = user_prop_add_boolean("Show transponder", true, ""),
        display_com = user_prop_add_boolean("Show COM radio", true, ""),
        unit_pressure = user_prop_add_enum("Unit of pressure", "inHg,hPa", "hPa", "inHg or hPa"),
        com_spacing = user_prop_add_enum("Radio frequency spacing", "8.33 kHz,25 kHz", "8.33 kHz", ""),
        default_vfr_squawk = user_prop_add_integer("Default VFR squawk code", 0, 7777, 4701, "Used as a quick select on the transponder edit screen"),
        screen_only = user_prop_add_boolean("Screen only", false, "Don't show instrument background and buttons")
    },
    persist = {
        unit_alt = persist_add("INSTR-UNITS", UNITS.IMPERIAL)
    }
}

return config