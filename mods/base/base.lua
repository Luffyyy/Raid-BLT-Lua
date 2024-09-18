-- Only run if we have the global table
if not _G or BLT then
	return
end

-- Localise globals
---@class _G
local _G = _G

-- BLT Global table
local BLT = {}
BLT.name = "BLT"
BLT.logname = "BLT"
BLT.Base = {}
BLT.Modules = {}
BLT.Menus = {}
BLT.Items = {}
BLT.Updaters = {}
BLT.PausedUpdaters = {}
BLT.DEBUG_MODE = false
_G.BLT = BLT

-- Logging
_G.LogLevel = {
	NONE = 0,
	ERROR = 1,
	WARN = 2,
	INFO = 3,
	VERBOSE = 4,
	DEBUG = 5,
	ALL = 6
}

BLT.LOG_LEVEL = _G.LogLevel.VERBOSE

BLT.LogPrefixes = {}
for key, lvl in pairs(_G.LogLevel) do
	BLT.LogPrefixes[lvl] = key:upper() .. ":"
end
BLT.LogPrefixes[LogLevel.WARN] = "WARNING:"

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
	self._envs = {}
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
	BLT:Require("Classes/UpdateCallbacks")
	BLT:Require("Classes/UpdateManager")
	BLT:Require("Classes/ModManager")
	BLT:Require("Classes/Localization")
	BLT:Require("Classes/NotificationsManager")
	BLT:Require("Classes/KeybindsManager")
	BLT:Require("Classes/PersistScripts")

	BLT:Require("Classes/ModuleBase")
	BLT:RequireFolder("Modules")

	-- Check for developer mode
	if BLT.DEBUG_MODE or FileIO:Exists("mods/developer.txt") then
		BLT.DEBUG_MODE = true
		BLT.LOG_LEVEL = _G.LogLevel.ALL
		self:_Log(LogLevel.DEBUG, "BLTSetup", "DEBUG MODE ON")
	end

	-- Create hook tables
	self.hook_tables = {
		pre = {},
		post = {},
		wildcards = {}
	}

	-- Override require and setup self
	self:OverrideRequire()
end

function BLT:Setup()
	BLT:Require("Classes/Utils/Utils")
	BLT:Require("Classes/CustomPackageManager")
	BLT:Require("Classes/FileManager")

	self:_Log(LogLevel.INFO, "BLTSetup", "Setup...")

	-- Setup modules
	self.Logs = BLTLogs:new()
	self.Mods = BLTModManager:new()
	self.Updates = BLTUpdateManager:new()
	self.Keybinds = BLTKeybindsManager:new()
	self.Localization = BLTLocalization:new() -- deprecated
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
	self.UpdatesMenu = BLTUpdatesMenu:new()

	_G.LuaModManager = {
		_languages = {},
		Constants = C,
		Mods = {}
	}
end

-- Info
function BLT:GetVersion() --Should get replaced by BLTModExtended
	return 1
end

function BLT:GetOS()
	return os.getenv("HOME") == nil and "windows" or "linux"
end

-- BLT Mod loading
function BLT:RunHookTable(hooks, path)
	if not hooks then
		return false
	end

	for i = 1, #hooks do
		self:RunHookFile(path, hooks[i])
	end
end

function BLT:_UpdateGlobalEnv(vars)
	for k, v in pairs(vars) do
		if k:byte(1) ~= 95 then -- ignore "private" vars that start with _
			rawset(_G, k, v)
		end
	end
end

function BLT:RunHookFile(path, hook_data)
	local C = BLTModManager.Constants

	local mod = hook_data.mod
	local env = setmetatable({
		_M = mod,
		[C.required_script_global] = path or false,
		[C.mod_path_global] = mod:GetPath() or false,
		[C.mod_global] = mod
	}, BLT._env_mt)

	-- Set global variables related to the current hook and mod
	self:_UpdateGlobalEnv(env)

	--mod:LogF(LogLevel.DEBUG, "BLTSetup", "Running hook file '%s' (from mod %s) for path '%s'.", hook_data.script, mod:GetId(), path)

	if rawget(_G, "loadfile") then
		-- Run hook files in a separate environment to protect the mod vars
		local f = _G.loadfile(hook_data.script, nil, nil, true) -- direct env is not supported; log errors via BLT
		if f then
			table.insert(self._envs, env)

			-- run hook
			f = setfenv(f, env)
			f(hook_data.mod)

			table.remove(self._envs)

			-- update globals
			local new_env = self._envs[#self._envs]
			if new_env then
				self:_UpdateGlobalEnv(new_env)
			end
		end
	else
		--self:_Log(LogLevel.DEBUG, "BLTSetup", "No 'loadfile' function available. Falling back to 'dofile'.")

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
		local args = { ... }
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
	self:_Log(LogLevel.INFO, "BLTSetup", "Loading mods for state:", _G)

	local mods_list = {}
	local C = BLTModManager.Constants
	self:LoadMods(C.mods_directory, mods_list)
	self:LoadMods(C.maps_directory, mods_list)
	return mods_list
end

function BLT:LoadMods(path, mods_list)
	-- Get all folders in mods directory
	local C = self.Mods.Constants
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
				self:_Log(LogLevel.INFO, "BLTSetup", "Loading mod:", directory)

				-- Read the file contents
				local mod_content = FileIO:ConvertScriptData(file:read("*all"), is_json and "json" or "custom_xml")
				file:close()

				-- Create a BLT mod from the loaded data
				if mod_content then
					local mod
					if is_json then
						mod = BLTMod:new(path, directory, mod_content)
					else
						mod = BLTModExtended:new(path, directory, mod_content, true)
					end

					-- Set global variables related to the current mod
					self:_UpdateGlobalEnv({
						_M = mod,
						[C.mod_path_global] = mod:GetPath() or false,
						[C.mod_global] = mod
					})

					mod:PostInit()
					table.insert(mods_list, mod)
				else
					self:_Log(LogLevel.ERROR, "BLTSetup", "An error occured while loading mod.txt from:", mod_path)
				end
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
		self:LogF(LogLevel.ERROR, "BLT:RegisterModule parameter #1, string or table expected got %s.", t)
		return
	end

	if not self.Modules[key] then
		self:LogF(LogLevel.INFO, "RegisterMod", "Registered module with key '%s'.", tostring(key))
		if t == "table" then
			for _, alt_key in pairs(key) do
				self.Modules[alt_key] = module
			end
		else
			self.Modules[key] = module
		end
	else
		self:LogF(LogLevel.ERROR, "RegisterMod", "Module with key '%s' already exists.", tostring(key))
	end
end

-- Updaters
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

-- Logging functions
function BLT:_get_mod(depth)
	local env = self._envs[#self._envs] or getfenv(depth or 2)
	local mod = table.get(env, "CurrentMod") or self
	return mod
end

function BLT:_Log(...)
	return BLTMod.Log(self, ...)
end

function BLT:Log(...)
	local mod = self:_get_mod(5)
	return BLTMod.Log(mod, ...)
end

function BLT:LogF(...)
	local mod = self:_get_mod(5)
	return BLTMod.LogF(mod, ...)
end

function BLT:LogC(...)
	local mod = self:_get_mod(5)
	return BLTMod.LogC(mod, ...)
end

function BLT:log(...)
	self:_Log(LogLevel.WARN, "DEPRECATED",
		"The BLT:log() function has been deprecated. Please use BLT:Log(lvl, cat, ...)")

	local mod = self:_get_mod(5)
	return BLTMod.log(mod, ...)
end

function BLT:_Farewell()
	QuickMenu:new(
		managers.localization:text("blt_farewell_rblt_title"),
		managers.localization:text("blt_farewell_rblt_text"),
		{
			[1] = {
				text = managers.localization:text("dialog_yes"),
				is_cancel_button = true,
			},
			[2] = {
				text = managers.localization:text("blt_farewell_open_sblt_page"),
				callback = function()
					local url = "https://modworkshop.net/mod/21065" -- FIXME: use actual SuperBLT for Raid url when that is released
					os.execute("cmd /c start " .. url) -- doesnt use BLT:OpenUrl because we want to open SBLT page in the browser
				end
			},
		},
		true
	)
	return true
end

-- Helpers
function BLT:OpenUrl(url)
	if Steam:overlay_enabled() then
		Steam:overlay_activate("url", url)
	else
		os.execute("cmd /c start " .. url)
	end
end

-- Perform startup
BLT:Initialize()
