BLTUpdateManager = BLTUpdateManager or class()
local BLTUpdateManager = BLTUpdateManager
function BLTUpdateManager:init()
	self.active_checks = 0
	self.started_checks = 0
	self.auto_updates = {}
	self.available_updates = {}
end

function BLTUpdateManager:AddAvailableUpdate(update)
	if update then
		self.available_updates[update.id] = update
		if BLT.UpdatesMenu then
			BLT.UpdatesMenu:AddUpdate(update, "normal", true)
		end
	end
end

function BLTUpdateManager:RemoveAvailableUpdate(update)
	for i, upd in ipairs(self.available_updates) do
		if upd.id == update.id then
			table.remove(self.available_updates, i)
			return
		end
	end
end

function BLTUpdateManager:GetAvailableUpdate(id)
	return self.available_updates[id]
end

function BLTUpdateManager:GetAvailableUpdates()
	return self.available_updates
end

function BLTUpdateManager:GetAvailableUpdateCount()
	return table.size(self.available_updates)
end

function BLTUpdateManager:UpdatesAvailable()
	return self:GetAvailableUpdateCount() > 0
end

function BLTUpdateManager:RegisterAutoUpdate(update)
	self.auto_updates[update.id] = update
end

function BLTUpdateManager:GetAutoUpdates()
	return self.auto_updates
end

function BLTUpdateManager:RunAutoCheckForUpdates()
	-- Don't run the autocheck twice
	if self._has_checked_for_updates then
		return
	end
	self._has_checked_for_updates = true

	call_on_next_update(callback(self, self, "_RunAutoCheckForUpdates"))
end

function BLTUpdateManager:_RunAutoCheckForUpdates()
	-- Place a notification that we're checking for autoupdates
	if BLT.Notifications then
		self:_SetNotification("blt_checking_updates", "blt_checking_updates_help", true)
	end

	-- Start checking all mods for updates
	local count = 0
	for _, update in pairs(self:GetAutoUpdates()) do
		if not update._config.manual_check then
			update:CheckForUpdates(callback(self, self, "clbk_got_update"))
			count = count + 1
		end
	end

	-- Remove notification if not getting updates
	if count < 1 then
		self:_RemoveNotification()
	end
end

function BLTUpdateManager:clbk_got_update(update, required, reason)

	-- Add the pending download if required
	if required then
		self:AddAvailableUpdate(update)
		if update._config.important and BLT.Options:GetValue("ImportantNotice") then
			local loc = managers.localization
			if update:DisallowsUpdate() then
				BLTUpdateCallbacks[update:GetDisallowCallback()](BLTUpdateCallbacks, update)
			else
				QuickMenu:new(
					loc:text("blt_mods_manager_important_title", { mod = update.display_name or update._mod.name }),
					loc:text("blt_mods_manager_important_help"), {
						{
							text = loc:text("dialog_yes"),
							callback = function()
								BLT.UpdatesMenu:SetEnabled(true)
							end
						},
						{
							text = loc:text("dialog_no"),
							is_cancel_button = true
						}
					})
			end
		end
	end

	-- Check if any updates are still checking
	local still_checking = false
	for _, upd in pairs(self:GetAutoUpdates()) do
		local checking = upd:IsCheckingForUpdates()
		if checking then
			still_checking = true
			break
		else
		end
	end

	if not still_checking then
		-- Add notification if we need updates
		if self:UpdatesAvailable() then
			self:_SetNotification("blt_checking_updates_required", "blt_checking_updates_required_help", true)
		else
			self:_SetNotification("blt_checking_updates_none_required", "blt_checking_updates_none_required_help", true)
		end
	end
end

function BLTUpdateManager:_RemoveNotification()
	if self._updates_notification then
		BLT.Notifications:remove_notification(self._updates_notification)
		self._updates_notification = nil
	end
end

function BLTUpdateManager:_SetNotification(title, text, localize)
	self:_RemoveNotification()
	self._updates_notification = BLT.Notifications:add_notification({
		title = localize and managers.localization:text(title) or title,
		text = localize and managers.localization:text(text) or text,
		icon = "ui/atlas/raid_atlas_hud",
		icon_texture_rect = { 891, 1285, 64, 64 },
		priority = 0
	})
end
