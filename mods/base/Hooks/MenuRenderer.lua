function MenuRenderer:special_btn_released(...)
	if self:active_node_gui() and self:active_node_gui().special_btn_released and self:active_node_gui():special_btn_released(...) then
		return true
	end

	return managers.menu_component:special_btn_released(...)
end
