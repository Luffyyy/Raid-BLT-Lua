local mm = MenuInput.mouse_moved
function MenuInput:MenuUIIsActive(...)
	local mc = managers.mouse_pointer._mouse_callbacks
	local last = mc[#mc]
	return last and get_type_name(last.parent) == "MenuUI" and last.parent.allow_full_input
end

function MenuInput:mouse_moved(...)
	if self:MenuUIIsActive() then
		return
	end
	return mm(self, ...)
end

local mp = MenuInput.mouse_pressed
function MenuInput:mouse_pressed(...)
	if self:MenuUIIsActive() then
		return
	end
	return mp(self, ...)
end

function MenuInput:disable_back(disable)
	self._back_disabled = disable
end

function MenuInput:ignore_back_once()
	self._ignore_back_once = true
end

-- Patch the original update function to add BLT UI checks
-- and support for "special_btn_released" component callbacks
function MenuInput:update(t, dt)
	if self._menu_plane then
		self._menu_plane:set_rotation(Rotation(math.sin(t * 60) * 40, math.sin(t * 50) * 30, 0))
	end

	self:_update_axis_status()

	do
		local bm_manager = managers.blackmarket
		if bm_manager and bm_manager:is_preloading_weapons() then
			return
		end
	end

	do
		local system_menu = managers.system_menu
		if system_menu and system_menu:is_active() and not system_menu:is_closing() then
			return
		end
	end

	do
		local raid_menu = managers.raid_menu
		if raid_menu._back_disabled then
			return
		end

		if raid_menu._ignore_back_once then
			raid_menu._ignore_back_once = nil
			return
		end
	end

	-- BLT MenuUI and Dialog checks
	if self._controller and self._accept_input and self._controller:get_input_pressed("cancel") and BLT.Dialogs:DialogOpened() then
		BLT.Dialogs:CloseLastDialog()
		return
	end

	if self:MenuUIIsActive() then
		return
	end
	-- //

	if self._page_timer > 0 then
		self:set_page_timer(self._page_timer - dt)
	end

	if not MenuInput.super.update(self, t, dt) and self._accept_input or self:force_input() then
		local axis_timer = self:axis_timer()

		if axis_timer.y <= 0 then
			if self:menu_up_input_bool() then
				managers.menu:active_menu().renderer:move_up()
				self:set_axis_y_timer(0.12)

				if self:menu_up_pressed() then
					self:set_axis_y_timer(0.3)
				end
			elseif self:menu_down_input_bool() then
				managers.menu:active_menu().renderer:move_down()
				self:set_axis_y_timer(0.12)

				if self:menu_down_pressed() then
					self:set_axis_y_timer(0.3)
				end
			end
		end

		if axis_timer.x <= 0 then
			if self:menu_left_input_bool() then
				managers.menu:active_menu().renderer:move_left()
				self:set_axis_x_timer(0.12)

				if self:menu_left_pressed() then
					self:set_axis_x_timer(0.3)
				end
			elseif self:menu_right_input_bool() then
				managers.menu:active_menu().renderer:move_right()
				self:set_axis_x_timer(0.12)

				if self:menu_right_pressed() then
					self:set_axis_x_timer(0.3)
				end
			end
		end

		local scroll_timer = self:scroll_timer()

		if scroll_timer.y <= 0 then
			if self:menu_scroll_up_input_bool() then
				managers.menu:active_menu().renderer:scroll_up()
				self:set_scroll_y_timer(0.12)

				if self:menu_scroll_up_pressed() then
					self:set_scroll_y_timer(0.3)
				end
			elseif self:menu_scroll_down_input_bool() then
				managers.menu:active_menu().renderer:scroll_down()
				self:set_scroll_y_timer(0.12)

				if self:menu_scroll_down_pressed() then
					self:set_scroll_y_timer(0.3)
				end
			end
		end

		if scroll_timer.x <= 0 then
			if self:menu_scroll_left_input_bool() then
				managers.menu:active_menu().renderer:scroll_left()
				self:set_scroll_x_timer(0.3)

				if self:menu_scroll_left_pressed() then
					self:set_scroll_x_timer(0.3)
				end
			elseif self:menu_scroll_right_input_bool() then
				managers.menu:active_menu().renderer:scroll_right()
				self:set_scroll_x_timer(0.3)

				if self:menu_scroll_right_pressed() then
					self:set_scroll_x_timer(0.3)
				end
			end
		end

		if self._page_timer <= 0 then
			if self:menu_previous_page_input_bool() then
				managers.menu:active_menu().renderer:previous_page()
				self:set_page_timer(0.12)

				if self:menu_previous_page_pressed() then
					self:set_page_timer(0.3)
				end
			elseif self:menu_next_page_input_bool() then
				managers.menu:active_menu().renderer:next_page()
				self:set_page_timer(0.12)

				if self:menu_next_page_pressed() then
					self:set_page_timer(0.3)
				end
			end

			if self._controller and self._accept_input then
				for _, button in ipairs(self.special_buttons) do
					if self._controller:get_input_pressed(button) then
						if managers.menu_component:special_btn_pressed(Idstring(button)) then
							local active_menu = managers.menu:active_menu()
							if active_menu then
								active_menu.renderer:disable_input(0.2)
							end
							break
						end

						-- things may still have changed at this point, recheck
						if not self._controller or not self._accept_input then
							break
						end
					end
				end
			end

			if managers.menu:active_menu() then
				if self._accept_input and self._controller and self._controller:get_input_pressed("confirm") and managers.menu:active_menu().renderer:confirm_pressed() then
					local active_menu = managers.menu:active_menu()
					if active_menu then
						active_menu.renderer:disable_input(0.2)
					end
				end

				if self._accept_input and self._controller and self._controller:get_input_pressed("back") and managers.menu:active_menu().renderer:back_pressed() then
					local active_menu = managers.menu:active_menu()
					if active_menu then
						active_menu.renderer:disable_input(0.2)
					end
				end

				if self._accept_input and self._controller and self._controller:get_input_pressed("cancel") and managers.menu:active_menu().renderer:back_pressed() then
					local active_menu = managers.menu:active_menu()
					if active_menu then
						active_menu.renderer:disable_input(0.2)
					end
				end

				self:_check_special_buttons2()
			end
		end
	end

	if not self._keyboard_used and self._mouse_active and self._accept_input and not self._mouse_moved then
		self:mouse_moved(managers.mouse_pointer:mouse(), managers.mouse_pointer:world_position())
	end

	self._mouse_moved = nil
end

MenuInput.special_buttons2 = {
	"menu_toggle_voice_message",
	"menu_respec_tree",
	"menu_switch_skillset",
	"menu_modify_item",
	"menu_preview_item",
	"menu_remove_item",
	"menu_preview_item_alt",
	"menu_toggle_legends",
	"menu_toggle_filters",
	"menu_toggle_ready",
	"toggle_chat",
	"menu_toggle_pp_drawboard",
	"menu_toggle_pp_breakdown",
	"trigger_left",
	"trigger_right",
	"menu_challenge_claim",
	"menu_tab_left",
	"menu_tab_right",
	"menu_mission_selection_start"
}

function MenuInput:_check_special_buttons2()
	if not self._controller then
		return
	end
	local active_menu = managers.menu:active_menu()
	if not active_menu then
		return
	end
	local active_renderer = active_menu.renderer
	for i = 1, #self.special_buttons2 do
		local button = self.special_buttons2[i]
		if self._accept_input and self._controller then
			if self._controller:get_input_pressed(button) then
				if active_renderer:special_btn_pressed(Idstring(button)) then
					active_renderer:disable_input(0.2)
					return true
				end
			elseif self._controller:get_input_released(button) then
				if active_renderer:special_btn_released(Idstring(button)) then
					active_renderer:disable_input(0.2)
					return true
				end
			end
		end
	end
end