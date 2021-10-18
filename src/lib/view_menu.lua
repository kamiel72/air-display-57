view_menu = {
    elements = nil
}

function view_menu.init(x,y, labels)
    bg = txt_add(" ", "background_color: black", x, y, 320, 30)
    view_menu.elements = group_add(bg)

    for i = 1,4 do
        group_obj_add(view_menu.elements, txt_add(labels[i], 
            "size:28px; font:Lato-Regular.ttf; color: white; valign: top; halign: center", 
            x + (i-1)*80, y-2, 80, 30))
    end
    
    return view_menu.elements
end

return view_menu