BLTNotificationsGui = BLTNotificationsGui or class(BLTCustomMenu)
local SPOT_W = 32
local BAR_W = 32
local BAR_H = 6
local BAR_X = (SPOT_W - BAR_W) / 2
local BAR_Y = 0
local TIME_PER_PAGE = 6
local CHANGE_TIME = 1
local PADDING = 10

function BLTNotificationsGui:init(ws, fullscreen_ws, node)
	self._next_time = Application:time() + TIME_PER_PAGE
	self._current = 0
	self._notifications = {}
	self._notifications_count = 0
	self._uid = 1000

	BLTNotificationsGui.super.init(self, ws, fullscreen_ws, node, "blt_notifications")
end

function BLTNotificationsGui:_setup()
	self._enabled = true

	-- Create panels
	self._panel = self._ws:panel():panel({
		layer = 20,
		w = 524,
		h = 152
	})
	self._panel:set_bottom(self._ws:panel():h() - 90)

	self._content_panel = self._panel:panel({ y = 24, h = self._panel:h() * 0.8 })
	self._buttons_panel = self._panel:panel({ y = self._content_panel:bottom() - 24, h = self._panel:h() * 0.2 })

	self._panel:rect({
		name = "background",
		color = tweak_data.gui.colors.raid_list_background,
		layer = -1,
		halign = "scale",
		valign = "scale"
	})

	self._panel:bitmap({
		name = "bg_line",
		w = 3,
		halign = "scale",
		valign = "scale",
		color = tweak_data.gui.colors.raid_red
	})

	-- Outline
	BoxGuiObject:new(self._content_panel, { sides = { 1, 1, 1, 1 } })
	self._content_outline = BoxGuiObject:new(self._content_panel, { sides = { 2, 2, 2, 2 } })

	-- Setup notification buttons
	self._bar = self._buttons_panel:bitmap({
		halign = "grow",
		valign = "grow",
		wrap_mode = "wrap",
		visible = false,
		x = BAR_X,
		y = BAR_Y,
		w = BAR_W,
		h = BAR_H
	})
	self:set_bar_width(BAR_W, true)

	-- Downloads notification
	self._downloads_panel = self._panel:panel({
		name = "downlaods",
		w = 38,
		h = 32,
		y = 8,
		layer = 100
	})
	self._downloads_panel:set_right(self._panel:w() - 8)

	self._downloads_count = self._downloads_panel:text({
		font_size = tweak_data.menu.pd2_medium_font_size,
		font = tweak_data.menu.pd2_medium_font,
		layer = 10,
		color = tweak_data.gui.colors.raid_white,
		text = "2",
		align = "center",
	})

	self._downloads_panel:bitmap({
		name = "downloads_line",
		h = 3,
		color = tweak_data.gui.colors.raid_red
	}):set_bottom(self._downloads_panel:h())

	-- Add notifications that have already been registered
	for _, notif in ipairs(BLT.Notifications:get_notifications()) do
		self:add_notification(notif)
	end

	BLT.Updates:RunAutoCheckForUpdates()
end

function BLTNotificationsGui:close()
	if alive(self._panel) then
		self._ws:panel():remove(self._panel)
	end
end

function BLTNotificationsGui:_rec_round_object(object)
	local x, y, w, h = object:shape()
	object:set_shape(math.round(x), math.round(y), math.round(w), math.round(h))
	if object.children then
		for i, d in ipairs(object:children()) do
			self:_rec_round_object(d)
		end
	end
end

--------------------------------------------------------------------------------

function BLTNotificationsGui:_get_uid()
	local id = self._uid
	self._uid = self._uid + 1
	return id
end

function BLTNotificationsGui:_get_notification(uid)
	local idx
	for i, data in ipairs(self._notifications) do
		if data.id == uid then
			idx = i
			break
		end
	end
	return self._notifications[idx], idx
end

function BLTNotificationsGui:add_notification(parameters)
	-- Create notification panel
	local new_notif = self._content_panel:panel({})
	local icon_size = new_notif:h() - PADDING * 2
	local icon

	if parameters.icon then
		icon = new_notif:bitmap({
			texture = parameters.icon,
			texture_rect = parameters.icon_texture_rect,
			color = parameters.color or tweak_data.gui.colors.raid_white,
			alpha = parameters.alpha,
			x = PADDING,
			y = PADDING,
			w = icon_size,
			h = icon_size,
		})
	end

	local _x = (icon and icon:right() or 0) + PADDING

	local title = new_notif:text({
		text = parameters.title or "No Title",
		font = tweak_data.menu.pd2_large_font,
		font_size = tweak_data.menu.pd2_large_font_size * 0.5,
		color = tweak_data.gui.colors.raid_white,
		x = _x,
		y = PADDING,
	})
	self:make_fine_text(title)

	local text = new_notif:text({
		text = parameters.text or "No Text",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = _x,
		w = new_notif:w() - _x,
		y = title:bottom(),
		h = new_notif:h() - title:bottom(),
		color = tweak_data.gui.colors.raid_white,
		alpha = 0.8,
		wrap = true,
		word_wrap = true,
	})

	local id = self:_get_uid()
	table.insert(self._notifications, {
		id = id,
		priority = parameters.priority or 0,
		parameters = parameters,
		panel = new_notif,
		title = title,
		text = text,
		icon = icon,
	})

	table.sort(self._notifications, function(a, b) return a.priority > b.priority end)
	self._notifications_count = #self._notifications

	-- Check notification visibility
	for i, notif in ipairs(self._notifications) do
		notif.panel:set_visible(i == 1)
	end

	self._current = 1
	self:_update_bars()

	return id
end

function BLTNotificationsGui:remove_notification(uid)
	local _, idx = self:_get_notification(uid)
	if idx then
		self._content_panel:remove(self._notifications[idx].panel)
		table.remove(self._notifications, idx)
		self._notifications_count = #self._notifications
		self:_update_bars()
	end
end

function BLTNotificationsGui:_update_bars()
	-- Remove old buttons
	for i, btn in ipairs(self._buttons) do
		self._buttons_panel:remove(btn)
	end
	self._buttons_panel:remove(self._bar)
	self._buttons = {}

	-- Add new notifications
	local last
	for i = 1, self._notifications_count do
		local page_button = self._buttons_panel:bitmap({
			name = tostring(i),
			color = tweak_data.gui.colors.raid_list_background,
			x = last and last:right() + 4 or (self._buttons_panel:w() / 2) - ((self._notifications_count / 2) * BAR_W),
			w = BAR_W,
			h = BAR_H
		})
		last = page_button
		-- FIXME?:
		-- commented out, because this looks very very wrong. no idea what was tried to accomplish here exactly
		-- last cant be null here, nor does 'middle' exist.
		--if not last then
		--	page_button:set_center_x(middle * (BAR_W + 4))
		--end
		page_button:set_center_y((self._buttons_panel:h() - page_button:h()) / 2)
		table.insert(self._buttons, page_button)
	end

	-- Add the time bar
	self._bar = self._buttons_panel:bitmap({
		halign = "grow",
		valign = "grow",
		wrap_mode = "wrap",
		color = tweak_data.gui.colors.raid_red,
		x = BAR_X,
		y = BAR_Y,
		w = BAR_W,
		h = BAR_H
	})
	self:set_bar_width(BAR_W, true)
	if #self._buttons > 0 then
		self._bar:set_position(self._buttons[1]:x() + BAR_X, self._buttons[1]:y() + BAR_Y)
	else
		self._bar:hide()
	end
end

function BLTNotificationsGui:set_bar_width(w, random)
	w = w or BAR_W
	self._bar_width = w

	self._bar:set_w(w)

	self._bar_x = not random and self._bar_x or math.random(1, 255)
	self._bar_y = not random and self._bar_y or math.random(0, math.round(self._bar:texture_height() / 2 - 1)) * 2
	local x = self._bar_x
	local y = self._bar_y
	local h = 6
	local mvector_tl = Vector3()
	local mvector_tr = Vector3()
	local mvector_bl = Vector3()
	local mvector_br = Vector3()

	mvector3.set_static(mvector_tl, x, y, 0)
	mvector3.set_static(mvector_tr, x + w, y, 0)
	mvector3.set_static(mvector_bl, x, y + h, 0)
	mvector3.set_static(mvector_br, x + w, y + h, 0)
	self._bar:set_texture_coordinates(mvector_tl, mvector_tr, mvector_bl, mvector_br)
end

local animating
function BLTNotificationsGui:_move_to_notification(destination)
	-- Animation
	local swipe_func = function(o, other_object, duration)
		if not alive(o) or not alive(other_object) then return end

		animating = true
		duration = duration or CHANGE_TIME

		o:show()
		other_object:show()
		other_object:set_alpha(1)
		other_object:set_x(o:w())
		local orig_x = o:x()
		local orig_other_x = other_object:x()
		over(duration, function(t)
			other_object:set_x(PD2Easing.inout_quart(orig_other_x, 0, t))
			o:set_x(PD2Easing.inout_quart(orig_x, -o:w(), t))
			o:set_alpha(PD2Easing.in_quart(1, 0, t))
		end)

		if alive(o) then
			o:set_x(0)
			o:hide()
		end
		if alive(other_object) then
			other_object:set_x(0)
			other_object:show()
			other_object:set_alpha(1)
		end

		animating = false
		self._current = destination
	end

	-- Stop all animations
	for _, notification in ipairs(self._notifications) do
		if alive(notification.panel) then
			notification.panel:stop()
			notification.panel:set_x(0)
			notification.panel:hide()
		end
	end

	-- Start swap animation for next notification
	local a = self._notifications[self._current]
	local b = self._notifications[destination]
	a.panel:animate(swipe_func, b.panel, CHANGE_TIME)

	-- Update bar
	self._bar:set_position(self._buttons[destination]:x() + BAR_X, self._buttons[destination]:y() + BAR_Y)
end

function BLTNotificationsGui:_move_notifications(dir)
	self._queued = self._current + dir
	while self._queued > self._notifications_count do
		self._queued = self._queued - self._notifications_count
	end
	while self._queued < 1 do
		self._queued = self._queued + 1
	end
end

function BLTNotificationsGui:_next_notification()
	self:_move_notifications(1)
end

function BLTNotificationsGui:update(t, dt)
	-- Update download count
	if BLT.Updates:UpdatesAvailable() then
		self._downloads_panel:show()
		self._downloads_count:set_text(tostring(BLT.Updates:GetAvailableUpdateCount()))
	else
		self._downloads_panel:hide()
	end

	-- Update notifications
	if self._notifications_count <= 1 then
		return
	end

	self._next_time = self._next_time or t + TIME_PER_PAGE

	if self._block_change then
		self._next_time = t + TIME_PER_PAGE
	else
		if t >= self._next_time then
			self:_next_notification()
			self._next_time = t + TIME_PER_PAGE
		end
		self:set_bar_width(BAR_W * (1 - (self._next_time - t) / TIME_PER_PAGE))
	end

	if not animating and self._queued then
		self:_move_to_notification(self._queued)
		self._queued = nil
	end
end

--------------------------------------------------------------------------------

function BLTNotificationsGui:mouse_moved(o, x, y)
	if not self._enabled then
		return
	end

	if alive(self._content_panel) and self._content_panel:inside(x, y) then
		self._content_outline:show()
		return true, "link"
	else
		self._content_outline:hide()
	end

	for i, button in ipairs(self._buttons) do
		if button:inside(x, y) then
			return true, "link"
		end
	end
end

function BLTNotificationsGui:mouse_pressed(o, button, x, y)
	if not self._enabled or button ~= Idstring("0") then
		return
	end

	for i, button in ipairs(self._buttons) do
		if button:inside(x, y) then
			local i = tonumber(button:name())
			if self._current ~= i then
				self:_move_to_notification(i)
				self._next_time = Application:time() + TIME_PER_PAGE
			end
			return true
		end
	end

	if alive(self._content_panel) and self._content_panel:inside(x, y) then
		BLT.UpdatesMenu:SetEnabled(true)
		return true
	end
end

function BLTNotificationsGui:input_focus()
	return nil
end

--------------------------------------------------------------------------------
-- Patch MenuComponentManager to create the BLT Notifications component

Hooks:Add("MenuComponentManagerInitialize", "BLTNotificationsGui.MenuComponentManagerInitialize", function(self)
	RaidMenuHelper:CreateComponent("blt_notifications", BLTNotificationsGui)
end)

--------------------------------------------------------------------------------
-- Patch main menu to add notifications menu component

Hooks:Add("CoreMenuData.LoadDataMenu", "BLTNotificationsGui.CoreMenuData.LoadDataMenu", function(menu_id, menu)
	if menu_id ~= "start_menu" then
		return
	end

	for _, node in ipairs(menu) do
		if node.menu_components then
			if node.name == "main" then
				node.menu_components = node.menu_components .. " blt_notifications"
			end
		end
	end
end)
