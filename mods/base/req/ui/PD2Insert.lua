--Thanks TdlQ for lua dump.
--This file contains code from payday 2.

--Change BLT fonts to exisiting ones
tweak_data.menu.pd2_massive_font = "ui/fonts/pf_din_text_comp_pro_medium_42"
tweak_data.menu.pd2_large_font = "ui/fonts/pf_din_text_comp_pro_medium_32"
tweak_data.menu.pd2_medium_font = "ui/fonts/pf_din_text_comp_pro_medium_24"
tweak_data.menu.pd2_small_font = "ui/fonts/pf_din_text_comp_pro_medium_18"

--Allow mods to hook to these classes(ex: BeardLib)
local function pre_require(path)
	local path_lower = path:lower()
	BLT:RunHookTable(BLT.hook_tables.pre, path_lower)
end

--Allow mods to call these classes(ex: BeardLib)
local function post_require(path)
	local path_lower = path:lower()
	BLT:RunHookTable(BLT.hook_tables.post, path_lower)
	for k, v in ipairs(BLT.hook_tables.wildcards) do
		BLT:RunHookFile(path, v.mod_path, v.script)
	end	
end

pre_require("lib/managers/menu/ScrollablePanel")
ScrollablePanel = ScrollablePanel or class()
local PANEL_PADDING = 10
local FADEOUT_SPEED = 5
local SCROLL_SPEED = 28
ScrollablePanel.SCROLL_SPEED = SCROLL_SPEED

function ScrollablePanel:init(parent_panel, name, data)
	data = data or {}
	self._alphas = {}
	self._x_padding = data.x_padding ~= nil and data.x_padding or data.padding ~= nil and data.padding or PANEL_PADDING
	self._y_padding = data.y_padding ~= nil and data.y_padding or data.padding ~= nil and data.padding or PANEL_PADDING
	self._force_scroll_indicators = data.force_scroll_indicators
	local layer = data.layer ~= nil and data.layer or 50
	data.name = data.name or name and name .. "Base"
	self._panel = parent_panel:panel(data)
	self._scroll_panel = self._panel:panel({
		name = name and name .. "Scroll",
		x = self:x_padding(),
		y = self:y_padding(),
		w = self._panel:w() - self:x_padding() * 2,
		h = self._panel:h() - self:y_padding() * 2
	})
	self._canvas = self._scroll_panel:panel({
		name = name and name .. "Canvas",
		w = self._scroll_panel:w(),
		h = self._scroll_panel:h()
	})

	if data.ignore_up_indicator == nil or not data.ignore_up_indicator then
		local scroll_up_indicator_shade = self:panel():panel({
			halign = "right",
			name = "scroll_up_indicator_shade",
			valign = "top",
			alpha = 0,
			layer = layer,
			x = self:x_padding(),
			y = self:y_padding(),
			w = self:canvas():w()
		})
	end

	if data.ignore_down_indicator == nil or not data.ignore_down_indicator then
		local scroll_down_indicator_shade = self:panel():panel({
			valign = "bottom",
			name = "scroll_down_indicator_shade",
			halign = "right",
			alpha = 0,
			layer = layer,
			x = self:x_padding(),
			y = self:y_padding(),
			w = self:canvas():w(),
			h = self:panel():h() - self:y_padding() * 2
		})
	end

	local texture, rect = "ui/atlas/raid_atlas_menu", {922, 752, 32, 32}
	local scroll_up_indicator_arrow = self:panel():bitmap({
		name = "scroll_up_indicator_arrow",
		halign = "right",
		valign = "top",
		alpha = 0,
		rotation = -90,
		texture = texture,
		texture_rect = rect,
		w = 16,
		h = 16,
		layer = layer,
		color = tweak_data.screen_colors.button_stage_2
	})

	scroll_up_indicator_arrow:set_top(self:y_padding() + 6)
	scroll_up_indicator_arrow:set_right(self:panel():w() - self:scrollbar_x_padding())

	local scroll_down_indicator_arrow = self:panel():bitmap({
		name = "scroll_down_indicator_arrow",
		valign = "bottom",
		alpha = 0,
		halign = "right",
		rotation = 90,
		texture = texture,
		texture_rect = rect,
		w = 16,
		h = 16,
		layer = layer,
		color = tweak_data.screen_colors.button_stage_2
	})

	scroll_down_indicator_arrow:set_bottom((self:panel():h() - self:y_padding()) - 6)
	scroll_down_indicator_arrow:set_right(self:panel():w() - self:scrollbar_x_padding())

	if data.left_scrollbar then
		scroll_up_indicator_arrow:set_left(2)
		scroll_down_indicator_arrow:set_left(2)
	end

	local bar_h = scroll_down_indicator_arrow:top() - scroll_up_indicator_arrow:bottom()
	self._scroll_bar = self:panel():panel({
		name = "scroll_bar",
		halign = "right",
		w = 8,
		layer = layer - 1,
		h = bar_h
	})
	self._scroll_bar:rect({
		name = "scroll",
		color = tweak_data.screen_colors.button_stage_2,
		x = 3,
		w = 2,
		halign = "scale",
		valign = "scale"
	})
	
	self._scroll_bar:set_bottom(scroll_down_indicator_arrow:top())
	self._scroll_bar:set_center_x(scroll_down_indicator_arrow:center_x())

	self._bar_minimum_size = data.bar_minimum_size or 5
	self._thread = self._panel:animate(self._update, self)
end

function ScrollablePanel:alive()
	return alive(self:panel())
end

function ScrollablePanel:panel()
	return self._panel
end

function ScrollablePanel:scroll_panel()
	return self._scroll_panel
end

function ScrollablePanel:canvas()
	return self._canvas
end

function ScrollablePanel:x_padding()
	return self._x_padding
end

function ScrollablePanel:y_padding()
	return self._y_padding
end

function ScrollablePanel:scrollbar_x_padding()
	if self._x_padding == 0 then
		return PANEL_PADDING
	else
		return self._x_padding
	end
end

function ScrollablePanel:scrollbar_y_padding()
	if self._y_padding == 0 then
		return PANEL_PADDING
	else
		return self._y_padding
	end
end

function ScrollablePanel:set_pos(x, y)
	if x ~= nil then
		self:panel():set_x(x)
	end

	if y ~= nil then
		self:panel():set_y(y)
	end
end

function ScrollablePanel:set_size(w, h)
	self:panel():set_size(w, h)
	self:scroll_panel():set_size(w - self:x_padding() * 2, h - self:y_padding() * 2)

	local scroll_up_indicator_arrow = self:panel():child("scroll_up_indicator_arrow")

	scroll_up_indicator_arrow:set_top(self:y_padding() + 6)
	scroll_up_indicator_arrow:set_right(self:panel():w() - self:scrollbar_x_padding())

	local scroll_down_indicator_arrow = self:panel():child("scroll_down_indicator_arrow")

	scroll_down_indicator_arrow:set_bottom((self:panel():h() - self:y_padding()) - 6)
	scroll_down_indicator_arrow:set_right(self:panel():w() - self:scrollbar_x_padding())
	self._scroll_bar:set_bottom(scroll_down_indicator_arrow:top())
	self._scroll_bar:set_center_x(scroll_down_indicator_arrow:center_x())
end

function ScrollablePanel:on_canvas_updated_callback(callback)
	self._on_canvas_updated = callback
end

function ScrollablePanel:canvas_max_width()
	return self:scroll_panel():w()
end

function ScrollablePanel:canvas_scroll_width()
	return (self:scroll_panel():w() - self:x_padding()) - 5
end

function ScrollablePanel:canvas_scroll_height()
	return self:scroll_panel():h()
end

function ScrollablePanel:update_canvas_size()
	local orig_w = self:canvas():w()
	local max_h = 0

	for i, panel in ipairs(self:canvas():children()) do
		local h = panel:y() + panel:h()

		if max_h < h then
			max_h = h
		end
	end

	local show_scrollbar = self:canvas_scroll_height() < max_h
	local max_w = show_scrollbar and self:canvas_scroll_width() or self:canvas_max_width()

	self:canvas():grow(max_w - self:canvas():w(), max_h - self:canvas():h())

	if self._on_canvas_updated then
		self._on_canvas_updated(max_w)
	end

	max_h = 0

	for i, panel in ipairs(self:canvas():children()) do
		local h = panel:y() + panel:h()

		if max_h < h then
			max_h = h
		end
	end

	if max_h <= self:scroll_panel():h() then
		max_h = self:scroll_panel():h()
	end

	self:set_canvas_size(nil, max_h)
end

function ScrollablePanel:set_canvas_size(w, h)
	if w == nil then
		w = self:canvas():w()
	end

	if h == nil then
		h = self:canvas():h()
	end

	if h <= self:scroll_panel():h() then
		h = self:scroll_panel():h()

		self:canvas():set_y(0)
	end

	self:canvas():set_size(w, h)

	local show_scrollbar = self:scroll_panel():h() < h

	if not show_scrollbar then
		self._scroll_bar:set_alpha(0)
		self._scroll_bar:set_visible(false)
		self:set_element_alpha_target("scroll_up_indicator_arrow", 0, 100)
		self:set_element_alpha_target("scroll_down_indicator_arrow", 0, 100)
		self:set_element_alpha_target("scroll_up_indicator_shade", 0, 100)
		self:set_element_alpha_target("scroll_down_indicator_shade", 0, 100)
	else
		self._scroll_bar:set_alpha(1)
		self._scroll_bar:set_visible(true)
		self:_set_scroll_indicator()
		self:_check_scroll_indicator_states()
	end
end

function ScrollablePanel:set_element_alpha_target(element, target, speed)
	local element_name = type(element) == "string" and element or element:name()
	self._alphas[element_name] = {
		current = self._alphas[element_name] and self._alphas[element_name].current or element.alpha and element:alpha() or 1,
		target = target,
		speed = speed or self._alphas[element_name] and self._alphas[element_name].speed or 5
	}
end

function ScrollablePanel:is_scrollable()
	return self:scroll_panel():h() < self:canvas():h()
end

function ScrollablePanel:scroll(x, y, direction)
	if self:panel():inside(x, y) then
		self:perform_scroll(SCROLL_SPEED * TimerManager:main():delta_time() * 200, direction)

		return true
	end
end

function ScrollablePanel:perform_scroll(speed, direction)
	if self:canvas():h() <= self:scroll_panel():h() then
		return
	end

	local scroll_amount = speed * direction
	local max_h = self:canvas():h() - self:scroll_panel():h()
	max_h = max_h * -1
	local new_y = math.clamp(self:canvas():y() + scroll_amount, max_h, 0)

	self:canvas():set_y(new_y)
	self:_set_scroll_indicator()
	self:_check_scroll_indicator_states()
end

function ScrollablePanel:scroll_to(y)
	if self:canvas():h() <= self:scroll_panel():h() then
		return
	end

	local scroll_amount = -y
	local max_h = self:canvas():h() - self:scroll_panel():h()
	max_h = max_h * -1
	local new_y = math.clamp(scroll_amount, max_h, 0)

	self:canvas():set_y(new_y)
	self:_set_scroll_indicator()
	self:_check_scroll_indicator_states()
end

function ScrollablePanel:scroll_with_bar(target_y, current_y)
	local arrow_size = self:panel():child("scroll_up_indicator_arrow"):size()
	local scroll_panel = self:scroll_panel()
	local canvas = self:canvas()
	if target_y < current_y then
		if target_y < scroll_panel:world_bottom() - arrow_size then
			local mul = (scroll_panel:h() - arrow_size * 2) / canvas:h()

			self:perform_scroll((current_y - target_y) / mul, 1)
		end

		current_y = target_y
	elseif current_y < target_y then
		if scroll_panel:world_y() + arrow_size < target_y then
			local mul = (scroll_panel:h() - arrow_size * 2) / canvas:h()

			self:perform_scroll((target_y - current_y) / mul, -1)
		end

		current_y = target_y
	end
end

function ScrollablePanel:release_scroll_bar()
	self._pressing_arrow_up = false
	self._pressing_arrow_down = false

	if self._grabbed_scroll_bar then
		self._grabbed_scroll_bar = false

		return true
	end
end

function ScrollablePanel:_set_scroll_indicator()
	local bar_h = self:panel():child("scroll_down_indicator_arrow"):top() - self:panel():child("scroll_up_indicator_arrow"):bottom()

	if self:canvas():h() ~= 0 then
		self._scroll_bar:set_h(math.max((bar_h * self:scroll_panel():h()) / self:canvas():h(), self._bar_minimum_size))
	end
end

function ScrollablePanel:_check_scroll_indicator_states()
	local up_alpha = self:canvas():top() < 0 and 1 or 0
	local down_alpha = self:scroll_panel():h() < self:canvas():bottom() and 1 or 0

	self:set_element_alpha_target("scroll_up_indicator_arrow", up_alpha, FADEOUT_SPEED)
	self:set_element_alpha_target("scroll_down_indicator_arrow", down_alpha, FADEOUT_SPEED)

	if self:y_padding() > 0 or self._force_scroll_indicators then
		self:set_element_alpha_target("scroll_up_indicator_shade", up_alpha, FADEOUT_SPEED)
		self:set_element_alpha_target("scroll_down_indicator_shade", down_alpha, FADEOUT_SPEED)
	end

	local up_arrow = self:panel():child("scroll_up_indicator_arrow")
	local down_arrow = self:panel():child("scroll_down_indicator_arrow")
	local canvas_h = self:canvas():h() ~= 0 and self:canvas():h() or 1
	local at = self:canvas():top() / (self:scroll_panel():h() - canvas_h)
	local max = (down_arrow:top() - up_arrow:bottom()) - self._scroll_bar:h()

	self._scroll_bar:set_top(up_arrow:bottom() + max * at)
end

function ScrollablePanel._update(o, self)
	while true do
		local dt = coroutine.yield()

		for element_name, data in pairs(self._alphas) do
			data.current = math.step(data.current, data.target, dt * data.speed)
			local element = self:panel():child(element_name)

			if alive(element) then
				element:set_alpha(data.current)
			end
		end
	end
end

function ScrollablePanel:mouse_moved(button, x, y)
	if self._grabbed_scroll_bar then
		self:scroll_with_bar(y, self._current_y)

		self._current_y = y

		return true, "grab"
	elseif alive(self._scroll_bar) and self._scroll_bar:visible() and self._scroll_bar:inside(x, y) then
		return true, "hand"
	elseif self:panel():child("scroll_up_indicator_arrow"):inside(x, y) then
		if self._pressing_arrow_up then
			self:perform_scroll(SCROLL_SPEED * 0.1, 1)
		end

		return true, "link"
	elseif self:panel():child("scroll_down_indicator_arrow"):inside(x, y) then
		if self._pressing_arrow_down then
			self:perform_scroll(SCROLL_SPEED * 0.1, -1)
		end

		return true, "link"
	end
end

function ScrollablePanel:mouse_clicked(o, button, x, y)
	if alive(self._scroll_bar) and self._scroll_bar:visible() and self._scroll_bar:inside(x, y) then
		return true
	end
end

function ScrollablePanel:mouse_pressed(button, x, y)
	if alive(self._scroll_bar) and self._scroll_bar:visible() and self._scroll_bar:inside(x, y) then
		self._grabbed_scroll_bar = true
		self._current_y = y

		return true
	elseif self:panel():child("scroll_up_indicator_arrow"):inside(x, y) then
		self._pressing_arrow_up = true

		return true
	elseif self:panel():child("scroll_down_indicator_arrow"):inside(x, y) then
		self._pressing_arrow_down = true

		return true
	end
end

function ScrollablePanel:mouse_released(button, x, y)
	return self:release_scroll_bar()
end
post_require("lib/managers/menu/ScrollablePanel")

Easing = Easing or {}
local mlerp = math.lerp
local mpow = math.pow
local msin = math.sin
local mcos = math.cos
local msqrt = math.sqrt
local mabs = math.abs
local masin = math.asin
local pi = math.pi

function Easing.linear(a, b, t)
	return mlerp(a, b, t)
end

function Easing.in_quad(a, b, t)
	return (b - a) * t * t + a
end

function Easing.out_quad(a, b, t)
	return -(b - a) * t * (t - 2) + a
end

function Easing.inout_quad(a, b, t)
	t = t * 2

	if t < 1 then
		return (b - a) * 0.5 * t * t + a
	else
		return -(b - a) * 0.5 * ((t - 1) * (t - 3) - 1) + a
	end
end

function Easing.outin_quad(a, b, t)
	t = t * 2
	local c = (b - a) * 0.5

	if t < 1 then
		return Easing.out_quad(a, c, t)
	else
		return Easing.in_quad(a + c, b, t - 1) + c
	end
end

function Easing.in_cubic(a, b, t)
	return (b - a) * t * t * t + a
end

function Easing.out_cubic(a, b, t)
	t = t - 1

	return (b - a) * (t * t * t + 1) + a
end

function Easing.inout_cubic(a, b, t)
	t = t * 2

	if t < 1 then
		return (b - a) * 0.5 * t * t * t + a
	else
		t = t - 2

		return (b - a) * 0.5 * (t * t * t + 2) + a
	end
end

function Easing.outin_cubic(a, b, t)
	t = t * 2
	local c = (b - a) * 0.5

	if t < 1 then
		return Easing.out_cubic(a, c, t)
	else
		return Easing.in_cubic(a + c, b, t - 1) + c
	end
end

function Easing.in_quart(a, b, t)
	return (b - a) * t * t * t * t + a
end

function Easing.out_quart(a, b, t)
	t = t - 1

	return -(b - a) * (t * t * t * t - 1) + a
end

function Easing.inout_quart(a, b, t)
	t = t * 2

	if t < 1 then
		return (b - a) * 0.5 * t * t * t * t + a
	else
		t = t - 2

		return -(b - a) * 0.5 * (t * t * t * t - 2) + a
	end
end

function Easing.outin_quart(a, b, t)
	t = t * 2
	local c = (b - a) * 0.5

	if t < 1 then
		return Easing.out_quart(a, c, t)
	else
		return Easing.in_quart(a + c, b, t - 1) + c
	end
end

function Easing.in_quint(a, b, t)
	return (b - a) * t * t * t * t * t + a
end

function Easing.out_quint(a, b, t)
	t = t - 1

	return (b - a) * (t * t * t * t * t + 1) + a
end

function Easing.inout_quint(a, b, t)
	t = t * 2

	if t < 1 then
		return (b - a) * 0.5 * t * t * t * t * t + a
	else
		t = t - 2

		return (b - a) * 0.5 * (t * t * t * t * t + 2) + a
	end
end

function Easing.outin_quint(a, b, t)
	t = t * 2
	local c = (b - a) * 0.5

	if t < 1 then
		return Easing.out_quint(a, c, t)
	else
		return Easing.in_quint(a + c, b, t - 1) + c
	end
end

function Easing.in_expo(a, b, t)
	if t == 0 then
		return a
	else
		local c = b - a

		return c * mpow(2, 10 * (t - 1)) - c * 0.001 + a
	end
end

function Easing.out_expo(a, b, t)
	if t == 1 then
		return b
	else
		local c = b - a

		return c * 1.001 * (-mpow(2, -10 * t) + 1) + a
	end
end

function Easing.inout_expo(a, b, t)
	if t == 1 then
		return b
	elseif t == 0 then
		return a
	end

	t = t * 2

	if t < 1 then
		local c = b - a

		return c * 0.5 * mpow(2, 10 * (t - 1)) - c * 0.0005 + a
	else
		t = t - 1
		local c = b - a

		return c * 0.5 * 1.0005 * (-mpow(2, -10 * t) + 2) + a
	end
end

function Easing.outin_expo(a, b, t)
	t = t * 2
	local c = (b - a) * 0.5

	if t < 1 then
		return Easing.out_expo(a, c, t)
	else
		return Easing.in_expo(a + c, b, t - 1) + c
	end
end