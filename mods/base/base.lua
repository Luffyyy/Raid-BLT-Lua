-- Only run if we have the global table
if not _G or BLT then
	return
end

-- Localise globals
local _G = _G
local io = io
local file = file

-- BLT Global table
BLT = {}
BLT.name = "BLT"
BLT.Base = {}
BLT.Modules = {}
BLT.Menus = {}
BLT.Items = {}
BLT.Updaters = {}
BLT.PausedUpdaters = {}

-- Load modules
BLT.path = "mods/base/"
function BLT:Require(path)
	dofile(string.format("%s%s", BLT.path, path .. ".lua"))
end

function BLT:RequireFolder(path)
	local dir = Path:Combine(BLT.path, path)
	for _, file in pairs(FileIO:GetFiles(dir)) do
		dofile(Path:Combine(dir, file))
	end
end

-- BLT base functions
function BLT:Initialize()
	-- Create environment holders
	self._env_mt = { __index = _G, __newindex = _G }
	BLT:Require("Classes/Utils/UtilsCore")
	BLT:Require("Classes/Utils/UtilsIO")
	BLT:Require("Classes/Utils/Utils")
	BLT:Require("Classes/Utils/Hooks")
	BLT:Require("Classes/Utils/Json")
	BLT:Require("Classes/Utils/Networking")
	BLT:Require("Classes/Utils/MenuHelper")
	BLT:Require("Classes/Utils/RaidMenuHelper")
	BLT:Require("Classes/Utils/DelayedCalls")
	
	BLT:Require("Classes/Utils/json")
	BLT:Require("Classes/Utils/QuickMenu")
	BLT:Require("Classes/Mod")
	BLT:Require("Classes/ModExtended")
	BLT:Require("Classes/Logs")
	BLT:Require("Classes/ModManager")
	BLT:Require("Classes/Localization")
	BLT:Require("Classes/NotificationsManager")
	BLT:Require("Classes/KeybindsManager")
	BLT:Require("Classes/PersistScripts")

	BLT:Require("Classes/ModuleBase")
	BLT:RequireFolder("Modules")

	-- Create hook tables
	self.hook_tables = {
		pre = {},
		post = {},
		wildcards = {}
	}

	-- Override require and setup self
	self:OverrideRequire()
end

function BLT:log(...)
	BLTMod.log(self, ...)
end

function BLT:Setup()
	BLT:Require("Classes/Utils/Utils")
	BLT:Require("Classes/CustomPackageManager")
	BLT:Require("Classes/FileManager")

	log("[BLT] Setup...")

	-- Setup modules
	self.Logs = BLTLogs:new()
	self.Mods = BLTModManager:new()
	self.Keybinds = BLTKeybindsManager:new()
	self.Localization = BLTLocalization:new()
	self.Notifications = BLTNotificationsManager:new()
	self.PersistScripts = BLTPersistScripts:new()

	Global.blt_checked_updates = Global.blt_checked_updates or {}
	local C = self.Mods.Constants
	
	rawset(_G, C.logs_path_global, C.mods_directory .. C.logs_directory)
	rawset(_G, C.save_path_global, C.mods_directory .. C.saves_directory)

	-- Initialization functions
	self.Logs:CleanLogs()
	self.Mods:SetModsList(self:ProcessModsList(self:FindMods()))

	self.Dialogs = BLTMenuDialogManager:new()
	self.ModsMenu = BLTModsMenu:new()

	_G.LuaModManager = {
		_languages = {},
		Constants = C,
		Mods = {}
	}
end

function BLT:GetVersion() --Should get replaced by BLTModExtended
	return 1
end

function BLT:GetOS()
	return os.getenv("HOME") == nil and "windows" or "linux"
end

function BLT:RunHookTable(hooks, path)
	if not hooks then
		return false
	end

	for i = 1, #hooks do
		self:RunHookFile(path, hooks[i])
	end
end

function BLT:RunHookFile(path, hook_data)
	local mod = hook_data.mod
	rawset(_G, BLTModManager.Constants.required_script_global, path or false)
	rawset(_G, BLTModManager.Constants.mod_path_global, mod:GetPath() or false)
	rawset(_G, BLTModManager.Constants.mod_global, mod)

	if rawget(_G, "loadfile") then
		-- Run hook files in a separate environment to protect the mod vars
		local env = setmetatable({
			[BLTModManager.Constants.required_script_global] = path or false,
			[BLTModManager.Constants.mod_path_global] = mod:GetPath() or false,
			[BLTModManager.Constants.mod_global] = mod
		}, BLT._env_mt)

		local f = _G.loadfile(hook_data.script, nil, nil, true) -- direct env is not supported; log errors via BLT
		if f then
			f = setfenv(f, env)
			f(hook_data.mod)
		end
	else
		self:log("WARNING: No 'loadfile' function available. Falling back to 'dofile'.")

		-- fall back to dofile
		dofile(hook_data.script)
	end
end

function BLT:OverrideRequire()
	if self.require then
		return false
	end

	-- Cache original require function
	self._require = self._require or _G.require

	-- Override require function to run hooks
	self.new_require = function(...)
		local args = {...}
		local path = args[1]
		local path_lower = path:lower()
		local require_result = nil

		self:RunHookTable(self.hook_tables.pre[path_lower], path_lower)
		require_result = self._require(...)
		self:RunHookTable(self.hook_tables.post[path_lower], path_lower)

		self:RunHookTable(self.hook_tables.wildcards, path_lower)

		return require_result
	end

	-- Load mods in first require(due to how the engine loads stuff that we need), then return the require to new_require.
	_G.require = function(...)
		self:Setup()
		_G.require = self.new_require
		self.new_require(...)
	end
end

function BLT:FindMods()
	log("[BLT] Loading mods for state: " .. tostring(_G))
	
	local mods_list = {}
	self:LoadMods(BLTModManager.Constants.mods_directory, mods_list)
	self:LoadMods(BLTModManager.Constants.mod_overrides_directory, mods_list)
	self:LoadMods(BLTModManager.Constants.maps_directory, mods_list)
	return mods_list
end

function BLT:LoadMods(path, mods_list)
	-- Get all folders in mods directory
	local folders = FileIO:GetFolders(path) or {}
	for _, directory in pairs(folders) do
		-- Check if this directory is excluded from being checked for mods (logs, saves, etc.)
		if not self.Mods:IsExcludedDirectory(directory) then
			local mod_path = path .. directory .. "/"
			local mod_defintion = mod_path .. "mod.xml"
			local is_json
			if not FileIO:Exists(mod_defintion) then
				mod_defintion = mod_path .. "mod.txt"
				is_json = true
			end

			-- Attempt to read the mod defintion file
			local file = io.open(mod_defintion)
			if file then
				log("[BLT] Loading mod: " .. tostring(directory))
				-- Read the file contents
				local mod_content = FileIO:ConvertScriptData(file:read("*all"), is_json and "json" or "custom_xml")
				file:close()
				-- Create a BLT mod from the loaded data
				if mod_content then
					if is_json then
						table.insert(mods_list, BLTMod:new(path, directory, mod_content))
					else
						table.insert(mods_list, BLTModExtended:new(path, directory, mod_content, true))
					end
				else
					log("[BLT] An error occured while loading mod.txt from: " .. tostring(mod_path))
				end
			elseif path == BLTModManager.Constants.mods_directory then --mod overrides is an optional directory.
				log("[BLT] Could not read or find mod definition in " .. tostring(directory))
			end
		end
	end
end

function BLT:ProcessModsList(mods_list)
	-- Prioritize mod load order
	table.sort(mods_list, function(a, b)
		return a:GetPriority() > b:GetPriority()
	end)

	return mods_list
end

function BLT:RegisterModule(key, module)
	local t = type(key)
	if t ~= "string" and t ~= "table" then
		self:log("[ERROR] BLT:RegisterModule parameter #1, string or table expected got %s", key and type(key) or "nil")
		return
	end

	if not self.Modules[key] then
		self:log("Registered module with key %s", key)
		if type(key) == "table" then
			for _, alt_key in pairs(key) do
				self.Modules[alt_key] = module
			end
		else
			self.Modules[key] = module
		end
	else
		self:log("[ERROR] Module with key %s already exists", key)
	end
end

function BLT:Update(t, dt)
	self.Dialogs:Update()
	for id, clbk in pairs(self.Updaters) do
		clbk(t, dt)
	end
end

function BLT:PausedUpdate(t, dt)
	for id, clbk in pairs(self.PausedUpdaters) do
		clbk(t, dt)
	end
end

function BLT:AddUpdater(id, clbk, paused, only_pause)
	if not only_pause then
		self.Updaters[id] = clbk
	end
	if paused then
		self.PausedUpdaters[id] = clbk
	end
end

function BLT:RemoveUpdater(id)
	self.Updaters[id] = nil
	self.PausedUpdaters[id] = nil
end

-- Perform startup
BLT:Initialize()