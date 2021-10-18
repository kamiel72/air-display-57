-- indicates if the display has booted and is running
local running = 0

-- AIR control display has a screen resolution of 320x240 pixels
-- coordinate indicates the top left corner of the display on the background
local screen_origin_x = 97;
local screen_origin_y = 140;

-- Instrument background
if not user_prop_get(config.user.screen_only) then
    img_add("bg.png", 0, 0, 512, 512)
else
    screen_origin_x = 0
    screen_origin_y = 0
end


-- Main instrument init
local buttons = controls.init(screen_origin_x, screen_origin_y)
local screen = screen_main.init(screen_origin_x, screen_origin_y)
opacity(screen, running)  -- we use opacity otherwise visible state gets messed up

-- Subscription callbacks
function new_alt_data(altitude, pressure)
    screen_main.update_alt(altitude, pressure)
end

function new_xpl_com_data(com1, com1_stby, com1_tx)
    screen_main.update_com(com1, com1_stby, com1_tx, false)
end

function new_fs_com_data(com1, com1_stby, com1_tx, com1_rx)
    screen_main.update_com(com1*100+0.01, com1_stby*100+0.01, com1_tx, com1_rx)
end

function new_xpl_transponder_data(mode, code, ident, reply, alt)
    local modeMap = { 1, 2, 3, 5, 4 }
    screen_main.update_xpdr(modeMap[mode+1], code, ident == 1, reply == 1, alt, false)
end

function new_fs_transponder_data(mode, code, alt)
    local modeMap = { 1, 2, 3, 4, 5, 5 }
    local ground = (mode == 5)
    screen_main.update_xpdr(modeMap[mode+1], code, false, false, alt, ground)
end

function xpl_start_shutdown(battery_voltage)
    start_shutdown(battery_voltage[1])
end

function start_shutdown(voltage)
    -- when supplied voltage is at least 9 volts the display boots
    if running == 0 and voltage >= 9 then
        running = 1
    -- when voltage drops below 8 volts the display shuts down
    elseif running == 1 and voltage < 8 then
        running = 0
    end
    opacity(screen, running)
end

-- Data subscriptions - we only add subscriptions for active views

-- Voltage subscription for startup - we alwaays need these
xpl_dataref_subscribe("sim/cockpit2/electrical/bus_volts", "FLOAT[6]", xpl_start_shutdown)
fs2020_variable_subscribe("ELECTRICAL MAIN BUS VOLTAGE", "Volts", start_shutdown)
fsx_variable_subscribe("ELECTRICAL MAIN BUS VOLTAGE", "Volts", start_shutdown)

if user_prop_get(config.user.display_com) then
    -- COM subscriptions
    xpl_dataref_subscribe("sim/cockpit2/radios/actuators/com1_frequency_hz", "INT",
                        "sim/cockpit/radios/com1_stdby_freq_hz", "INT",
                        "sim/atc/com1_active", "BOOL", new_xpl_com_data)
    fsx_variable_subscribe("COM ACTIVE FREQUENCY:1", "Mhz",
                          "COM STANDBY FREQUENCY:1", "Mhz", 
                          "COM TRANSMIT:1", "Bool", 
                          "COM RECEIVE ALL", "Bool", new_fs_com_data)
    fs2020_variable_subscribe("COM ACTIVE FREQUENCY:1", "Mhz",
                             "COM STANDBY FREQUENCY:1", "Mhz",
                             "COM TRANSMIT:1", "Bool", 
                             "COM RECEIVE ALL", "Bool", new_fs_com_data) 
end

if user_prop_get(config.user.display_alt) then
    -- Altimeter subscriptions
    xpl_dataref_subscribe("sim/flightmodel/misc/h_ind", "FLOAT",
                        "sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot", "FLOAT", new_alt_data)
    fsx_variable_subscribe("INDICATED ALTITUDE", "Feet",
                            "KOHLSMAN SETTING HG", "inHg", new_alt_data)
    fs2020_variable_subscribe("INDICATED ALTITUDE", "Feet",
                              "KOHLSMAN SETTING HG", "inHg", new_alt_data) 
end

if user_prop_get(config.user.display_xpdr) then
    -- Transponder subscriptions
    xpl_dataref_subscribe("sim/cockpit/radios/transponder_mode","INT",
                        "sim/cockpit/radios/transponder_code", "INT",
                        "sim/cockpit/radios/transponder_id", "INT",
                        "sim/cockpit/radios/transponder_light", "INT", 
                        "sim/flightmodel/misc/h_ind", "FLOAT", new_xpl_transponder_data)
    fsx_variable_subscribe("TRANSPONDER STATE:1", "Enum", 
                            "TRANSPONDER CODE:1", "Number", 
                            "INDICATED ALTITUDE", "Feet", new_fs_transponder_data)
    fs2020_variable_subscribe("TRANSPONDER STATE:1", "Enum", 
                              "TRANSPONDER CODE:1", "Number", 
                              "INDICATED ALTITUDE", "Feet", new_fs_transponder_data)
end



