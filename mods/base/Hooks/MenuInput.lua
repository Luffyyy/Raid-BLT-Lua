local mm = MenuInput.mouse_moved
function MenuInput:MenuUINotActive(...)
    local mc = managers.mouse_pointer._mouse_callbacks
    local last = mc[#mc]
    return not last or get_type_name(last.parent) ~= "MenuUI" or last.parent.allow_full_input
end

function MenuInput:mouse_moved(...)
    if self:MenuUINotActive() then
        return mm(self, ...)
    end
end

local mp = MenuInput.mouse_pressed
function MenuInput:mouse_pressed(...)
    if self:MenuUINotActive() then
        return mp(self, ...)
    end
end

function MenuInput:disable_back(disable)
	self._back_disabled = disable
end

function MenuInput:ignore_back_once()
    self._ignore_back_once = true
end

local up = MenuInput.update
function MenuInput:update(...)
    self:any_keyboard_used()
    if self._accept_input then
        if self._controller then
            if managers.raid_menu._back_disabled then
                return
            end
            if managers.raid_menu._ignore_back_once then
                managers.raid_menu._ignore_back_once = nil
                return
            end
            if self._controller:get_input_pressed("cancel") and BLT.Dialogs:DialogOpened() then
                BLT.Dialogs:CloseLastDialog()
                return
            end
            if self:MenuUINotActive() then
                up(self, ...)
            end
        end
    else
        up(self, ...)
    end
end

function MenuInput:activate_mouse(position, controller_activated)
	if controller_activated and managers.controller:get_default_wrapper_type() ~= "pc" and managers.controller:get_default_wrapper_type() ~= "steam" then
		return true
	end

	self._mouse_active = true
	local data = {
		mouse_move = callback(self, self, "mouse_moved"),
		mouse_press = callback(self, self, "mouse_pressed"),
		mouse_release = callback(self, self, "mouse_released"),
		mouse_click = callback(self, self, "mouse_clicked"),
		mouse_double_click = callback(self, self, "mouse_double_click"),
		id = self._menu_name
	}

	managers.mouse_pointer:use_mouse(data, position)
end
