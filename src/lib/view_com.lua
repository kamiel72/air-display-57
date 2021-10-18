view_com = {
    elements = nil,
    editor = nil,
    editing = false,
    stby_freq = 0.0
}

local D = {
    L = {
        width = 320,
        height = 210,
        char_size_l = 90,
        char_size_m = 60,
        char_size_s = 28,
        char_h_l = 75,
        char_h_m = 50,
        char_h_s = 30
    },
    M = {
        width = 320,
        height = 100,
        char_size_l = 80,
        char_size_m = 50,
        char_size_s = 28,
        char_h_l = 65,
        char_h_m = 50,
        char_h_s = -14
    }
}

local com1_freq = nil
local com1_stby_freq = nil
local com1_label = nil
local com1_stby_label = nil
local com1_tx_state = nil
local com1_rx_state = nil

-- draw view - dimensions are determined by 
function view_com.init(x, y, size)
    bg = txt_add(" ", "", x, y, D[size].width, D[size].height)
    com1_freq = txt_add("---.--", string.format("size:%dpx; font:Lato-Regular.ttf; color: white; halign:right; valign: top", D[size].char_size_l), x, y - 10, D[size].width, D[size].char_h_l)
    com1_label = txt_add("COM1", string.format("size:%dpx; font:Lato-Regular.ttf; color: white; halign:right; valign: top;", D[size].char_size_s), x, y + D[size].char_h_l - 10, D[size].width, D[size].char_h_s)
    
    com1_stby_freq = txt_add("---.--", string.format("size:%dpx; font:Lato-Regular.ttf; color: cyan; halign:right", D[size].char_size_m), x, y + D[size].char_h_l + D[size].char_h_s, D[size].width, D[size].char_h_m)
    com1_stby_label = txt_add("COM1 STBY", string.format("size:%dpx; font:Lato-Regular.ttf; color: cyan; halign:right; valign: top", D[size].char_size_s), x, y + D[size].char_h_l + D[size].char_h_m + D[size].char_h_s, D[size].width, D[size].char_h_s)
    com1_tx_state = img_add("radio-tx.png", x + 10, y + 10, 20, 20)
    com1_rx_state = img_add("radio-rx.png", x + 10, y + D[size].char_h_l / 2, 20, 20)
    visible(com1_tx_state, false)
    visible(com1_rx_state, false)

    if size ~= "L" then
        txt_style(com1_freq, "color: black")
        txt_style(com1_stby_freq, "color: DarkTurquoise")
        txt_style(bg, "background_color: white")
        visible(com1_label, false)
        visible(com1_stby_label, false)
    end
    view_com.elements = group_add(com1_freq, com1_stby_freq, com1_label, com1_stby_label, com1_tx_state, com1_rx_state, bg)

    return view_com.elements
end

-- 
function view_com.update(com1, com1_stby, com1_tx, com1_rx)
    -- we store freq to be able to edit it
    view_com.stby_freq = com1_stby
    txt_set(com1_freq, string.format("%.03f", com1 / 100))
    txt_set(com1_stby_freq, string.format("%.03f", com1_stby / 100))
    visible(com1_tx_state, com1_tx)
    visible(com1_rx_state, com1_rx)
end

function view_com.start_edit()
    if not view_com.editing then
        view_com.editing = true
        edit_com.start_edit(view_com.stby_freq)
    end
end

function view_com.cancel_edit()
    view_com.editing = false
end

function view_com.toggle_channel()
    if not view_com.editing then
        -- toggles active and standby channels
        fs2020_event("COM_STBY_RADIO_SWAP")
        fsx_event("COM_STBY_RADIO_SWAP") 
        xpl_command("sim/radios/com1_standy_flip")
    end
end

return view_com