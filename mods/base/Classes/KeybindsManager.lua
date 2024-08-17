BLTKeybind = BLTKeybind or class()

local BLTKeybind = BLTKeybind
BLTKeybind.StateMenu = 1
BLTKeybind.StateGame = 2
BLTKeybind.StatePausedGame = 3
function BLTKeybind:init(parent_mod, parameters)
	self._mod = parent_mod

	self._id = parameters.keybind_id or "missing_id"
	self._key = {}
	self._file = parameters.script_path
	self._callback = parameters.callback

	self._allow_menu = parameters.run_in_menu or false
	self._allow_game = parameters.run_in_game or false
	self._allow_paused_game = parameters.run_in_paused_game or false

	self._show_in_menu = parameters.show_in_menu
	if self._show_in_menu == nil then
		self._show_in_menu = true
	end
	self._name = parameters.name or false
	self._desc = parameters.desc or parameters.description	or false
	self._localize = parameters.localized or false
	self._localize_desc = parameters.localize_desc or false
	self:SetKeys(BLT.Options:GetValue("Keybinds")[self:Id()] or {})
end

function BLTKeybind:ParentMod()
	return self._mod
end

function BLTKeybind:Id()
	return self._id
end

function BLTKeybind:SetKey(key, force)
	self:_SetKey(force or "pc", key)
end

function BLTKeybind:_SetKey(idx, key)
	if not idx then
		return false
	end
	BLT:LogF(LogLevel.INFO, "BLTKeybind", "Bound %s to %s", tostring(self:Id()), tostring(key))
	self._key[idx] = key

	BLT.Options:GetValue("Keybinds")[self:Id()] = self:Keys()
	BLT.Options:Save()
end

function BLTKeybind:Key()
	return self._key.pc
end

function BLTKeybind:Keys()
	return self._key
end

function BLTKeybind:SetKeys(keys)
	self._key = keys
end

function BLTKeybind:HasKey()
	return (self:Key() and self:Key() ~= "")
end

function BLTKeybind:File()
	return self._file
end

function BLTKeybind:Callback()
	return self._callback
end

function BLTKeybind:ShowInMenu()
	return self._show_in_menu
end

function BLTKeybind:Name()
	if not self._name then
		return managers.localization:text("blt_no_name")
	end
	if self:IsLocalized() then
		return managers.localization:text(self._name)
	else
		return self._name
	end
end

function BLTKeybind:Description()
	if not self._desc then
		return managers.localization:text("blt_no_desc")
	end
	if self:IsDescriptionLocalized() then
		return managers.localization:text(self._desc)
	else
		return self._desc
	end
end

function BLTKeybind:IsLocalized()
	return self._localize
end

function BLTKeybind:IsDescriptionLocalized()
	return self._localize_desc
end

function BLTKeybind:AllowExecutionInMenu()
	return self._allow_menu
end

function BLTKeybind:AllowExecutionInGame()
	return self._allow_game
end

function BLTKeybind:AllowExecutionInPausedGame()
	return self._allow_paused_game
end

function BLTKeybind:CanExecuteInState(state)
	if state == BLTKeybind.StateMenu then
		return self:AllowExecutionInMenu()
	elseif state == BLTKeybind.StateGame then
		return self:AllowExecutionInGame()
	elseif state == BLTKeybind.StatePausedGame then
		return self:AllowExecutionInPausedGame()
	end
	return false
end

function BLTKeybind:Execute()
	if self:File() then
		local path = Application:nice_path(self:ParentMod():GetPath() .. "/" .. self:File(), false)
		dofile(path)
	end
	if self:Callback() then
		self:Callback()()
	end
end

function BLTKeybind:IsActive()
	local mod = self:ParentMod()
	return mod:WasEnabledAtStart() and mod:IsEnabled()
end

function BLTKeybind:__tostring()
	return "[BLTKeybind " .. tostring(self:Id()) .. "]"
end

--------------------------------------------------------------------------------

BLTKeybindsManager = BLTKeybindsManager or class()
local BLTKeybindsManager = BLTKeybindsManager

function BLTKeybindsManager:init()
	self._keybinds = {}
	self._potential_keybinds = {}
end

function BLTKeybindsManager:register_keybind(mod, parameters)
	local bind = BLTKeybind:new(mod, parameters)
	table.insert(self._keybinds, bind)
	mod:Log(LogLevel.INFO, "BLTKeybindsManager", "Registered keybind", bind)

	-- Check through the potential keybinds for the added bind and restore it's key
	for i, bind_data in ipairs(self._potential_keybinds) do
		local success = self:_restore_keybind(bind_data)
		if success then
			table.remove(self._potential_keybinds, i)
			break
		end
	end

	return bind
end

function BLTKeybindsManager:keybinds()
	return self._keybinds
end

function BLTKeybindsManager:has_keybinds()
	return table.size(self:keybinds()) > 0
end

function BLTKeybindsManager:has_menu_keybinds()
	for _, bind in ipairs(self:keybinds()) do
		if bind:ShowInMenu() then
			return true
		end
	end
	return false
end

function BLTKeybindsManager:get_keybind(id)
	for _, bind in ipairs(self._keybinds) do
		if bind:Id() == id then
			return bind
		end
	end
end

Hooks:Add("CustomizeControllerOnKeySet", "CustomizeControllerOnKeySet.BLTKeybindsManager",
	function(connection_name, button)
		local bind = BLT.Keybinds:get_keybind(connection_name)
		if bind then
			bind:SetKey(button)
		end
	end)

--------------------------------------------------------------------------------
-- Run keybinds

function BLTKeybindsManager:update(t, dt, state)
	-- Create inputs if needed
	if not self._input_keyboard then
		self._input_keyboard = Input:keyboard()
	end
	if not self._input_mouse then
		self._input_mouse = Input:mouse()
	end

	if managers then
		if managers.hud and managers.hud:chat_focus() then
			-- Don't run while chatting ingame
			return
		elseif managers.menu_component and managers.menu_component:input_focus() then -- This is a quick fix, I think this is the one for Raid.
			-- Don't run while chatting in lobby
			return
		elseif managers.menu then
			local menu = managers.menu:active_menu()
			if menu and menu.renderer then
				local node_gui = menu.renderer:active_node_gui()
				if node_gui and node_gui._listening_to_input then
					-- Don't run while rebinding keys
					return
				end
			end
		end
	end

	-- Run keybinds
	for _, bind in ipairs(self:keybinds()) do
		if bind:IsActive() and bind:HasKey() and bind:CanExecuteInState(state) then
			local key = bind:Key()
			local key_pressed
			if string.find(key, "mouse ") == 1 then
				key_pressed = self._input_mouse:pressed(Idstring(key:sub(7)))
			else
				key_pressed = self._input_keyboard:pressed(Idstring(key))
			end
			if key_pressed then
				bind:Execute()
			end
		end
	end
end

Hooks:Add("MenuUpdate", "BLT.Keybinds.MenuUpdate", function(t, dt)
	BLT.Keybinds:update(t, dt, BLTKeybind.StateMenu)
end)

Hooks:Add("GameSetupUpdate", "BLT.Keybinds.Update", function(t, dt)
	BLT.Keybinds:update(t, dt, BLTKeybind.StateGame)
end)

Hooks:Add("GameSetupPausedUpdate", "BLT.Keybinds.PausedUpdate", function(t, dt)
	BLT.Keybinds:update(t, dt, BLTKeybind.StatePausedGame)
end)
