BLT.Items.Toggle = BLT.Items.Toggle or class(BLT.Items.Item)
local Toggle = BLT.Items.Toggle
Toggle.type_name = "Toggle"
function Toggle:Init()
	Toggle.super.Init(self)
	local s = self.items_size - 6
	local fgcolor = self:GetForeground()
	self.toggle = self.panel:bitmap({
		name = "toggle",
		w = s,
		h = s,
		color = fgcolor,
		texture = "ui/atlas/menu/raid_atlas_menu",
		texture_rect = { 575, 385, 34, 34 },
		layer = 5,
	})
	local s = self.value and s - 8 or 0
	self.toggle_value = self.panel:bitmap({
		name = "toggle_value",
		w = s,
		h = s,
		texture = "ui/atlas/menu/raid_atlas_menu",
		texture_rect = { 341, 997, 22, 22 },
		color = fgcolor,
		layer = 5,
	})
	self.toggle:set_center_y(self.panel:h() / 2)
	self.toggle:set_right(self.panel:w() - 2)
	self.toggle_value:set_center(self.toggle:center())
	self:UpdateToggle(true)
end

function Toggle:SetEnabled(enabled)
	Toggle.super.SetEnabled(self, enabled)
end

function Toggle:SetValue(value, run_callback)
	if Toggle.super.SetValue(self, value, run_callback) then
		self:UpdateToggle(true)
		return true
	else
		return false
	end
end

function Toggle:UpdateToggle(value_changed, highlight)
	local value = self.value
	if alive(self.panel) then
		local fgcolor = self:GetForeground(highlight)
		local s = value and self.items_size - 14 or 0
		play_color(self.toggle, fgcolor)
		play_anim(self.toggle_value, {
			after = function()
				self.toggle_value:set_center(self.toggle:center())
			end,
			set = { w = s, h = s, color = fgcolor }
		})
	end
end

function Toggle:MousePressed(button, x, y)
	if not self:MouseCheck(true) then
		return
	end
	if button == Idstring("0") then
		self:SetValue(not self.value)
		if managers.menu_component then
			managers.menu_component:post_event(self.value and "box_tick" or "box_untick")
		end
		Toggle.super.MousePressed(self, button, x, y)
		return true
	end
end

function Toggle:KeyPressed(o, k)
	if k == Idstring("enter") then
		self:SetValue(not self.value)
		self:RunCallback()
	end
end

function Toggle:DoHighlight(highlight)
	Toggle.super.DoHighlight(self, highlight)
	self:UpdateToggle(false, highlight)
end
