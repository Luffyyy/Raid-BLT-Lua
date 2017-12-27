local mm = MenuInput.mouse_moved
function MenuInput:mouse_moved(...)
    local mc = managers.mouse_pointer._mouse_callbacks
    local last = mc[#mc]
    if not last or get_type_name(last.parent) ~= "MenuUI" or last.parent.allow_full_input then
        return mm(self, ...)
    end
end

local mp = MenuInput.mouse_pressed
function MenuInput:mouse_pressed(...)
    local mc = managers.mouse_pointer._mouse_callbacks
    local last = mc[#mc]
    if not last or get_type_name(last.parent) ~= "MenuUI" or last.parent.allow_full_input then
        return mp(self, ...)
    end
end