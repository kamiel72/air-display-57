view_transponder = {
    elements = {},
    editing = false,
    mode = nil,
    code = 0
}

local D = {
     L = {
         width = 320,
         height = 210,
         char_size_l = 165,
         char_size_m = 50,
         char_h_l = 150,
         char_h_m = 45,
         mode_margin_top = 165,
     },
     M = {
        width = 320,
        height = 100,
        char_size_l = 95,
        char_size_m = 35,
        char_h_l = 100,
        char_h_m = 30,
        mode_margin_top = 40,
     },
     S = {
        width = 120,
        height = 105,
        char_size_l = 55,
        char_size_m = 25,
        char_h_l = 100,
        char_h_m = 30,
        mode_margin_top = 50
     }
}
local T = {
    LIGHT = {
        color_1 = "black",
        color_2 = "gold",
        color_3 = "DarkTurquoise"
    },
    DARK = {
         color_1 = "white",
         color_2 = "#FAE800",
         color_3 = "cyan"
    }
}

local reply_icon = nil
local code_label = nil
local mode_label = nil
local ident_label = nil
local flight_level = nil
local ground_icon = nil
local idnt_label = nil

function get_flight_level(alt)
    local fl = var_round(alt / 100, 0)
    if alt == 0 then
        return " "
    else
        return string.format("FL%03d", fl)
    end
end

function view_transponder.init(x, y, size, theme)
    code_label = txt_add(" ", string.format("size: %dpx; font:Lato-Regular.ttf; color: %s; halign: center; valign: center;", D[size].char_size_l, T[theme].color_1), 
        x, y, D[size].width, D[size].char_h_l)
    mode_label = txt_add(" ", string.format("size: %dpx; font:Lato-Regular.ttf; color: %s; valign: bottom; halign: left", D[size].char_size_m, T[theme].color_1),
        x + 25, y + D[size].mode_margin_top, D[size].width - 28, D[size].char_h_m)
    idnt_label = txt_add("IDNT", string.format("size: %dpx; font:Lato-Regular.ttf; color: %s; valign: bottom; halign: left;", D[size].char_size_m, T[theme].color_2),
        x + 25, y + D[size].mode_margin_top, D[size].width - 28, D[size].char_h_m)
    flight_level = txt_add(" ", string.format("size: %dpx; font:Lato-Regular.ttf; color: %s; valign: bottom; halign: right;", D[size].char_size_m, T[theme].color_3),
        x, y + D[size].mode_margin_top + D[size].char_h_m, D[size].width - 3, D[size].char_h_m)
    reply_icon = img_add("transponder-reply.png", x, y + D[size].height - 25, 20, 20)
    ground_icon = img_add("transponder-ground.png", x + 25, y + D[size].height - D[size].char_h_m - 15, 48, 20)
    visible(reply_icon, false)
    visible(ground_icon, false)
    visible(idnt_label, false)

    if size == "L" then
        move(flight_level, nil, y + D[size].height - D[size].char_h_m)
    elseif size == "M" then 
        txt_style(code_label, "halign: left; valign: top")
        txt_style(mode_label, "halign: right")
        txt_style(idnt_label, "halign: right")
        move(code_label, nil, y - 10)
    elseif size == "S" then
        move(ground_icon, x + 5)
        move(reply_icon, x + 10)
        move(flight_level, nil, y + D[size].height - D[size].char_h_m)
        txt_style(code_label, "valign: top")
        txt_style(mode_label, "halign: right")
        txt_style(idnt_label, "halign: right")
    end

    view_transponder.elements = group_add(code_label, mode_label, idnt_label, flight_level, reply_icon, ground_icon)
    return view_transponder.elements
end

function view_transponder.update(mode, code, ident, reply, alt, ground)
    local modes = { "OFF", "STBY", "ON", "TST", "ALT" }
    view_transponder.mode = modes[mode]
    view_transponder.code = code
    txt_set(mode_label, modes[mode])
    txt_set(code_label, string.format("%d", code))
    txt_set(flight_level, get_flight_level(alt))
    visible(reply_icon, reply)
    visible(idnt_label, ident)
    visible(mode_label, not ident)
    visible(ground_icon, ground)
end

function view_transponder.start_edit()
    if not view_transponder.editing then
        view_transponder.editing = true
        edit_xpdr.start_edit(view_transponder.mode, view_transponder.code, view_transponder.end_edit)
    end
end

function view_transponder.end_edit()
    view_transponder.editing = false
end

function view_transponder.toggle_mode()
    if not view_transponder.editing then
        edit_xpdr.toggle_mode()
    end
end

function view_transponder.ident()
    if not view_transponder.editing then
        -- Trigger IDENT
        xpl_command("sim/transponder/transponder_ident")
        fsx_event("H:TransponderIDT")
        fs2020_event("H:TransponderIDT")
    end
end

return view_transponder