blt.forcepcalls(true)

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
BLT.version = 1.0
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
	BLT:Require("Classes/ModDependency")
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

	log("[BLT] Setup...")

	-- Setup modules
	self.Logs = BLTLogs:new()
	self.Mods = BLTModManager:new()
	self.Keybinds = BLTKeybindsManager:new()
	self.Localization = BLTLocalization:new()
	self.Notifications = BLTNotificationsManager:new()
	self.PersistScripts = BLTPersistScripts:new()
	
	local C = self.Mods.Constants
	if not FileIO:Exists(C.maps_directory) then
	--	FileIO:MakeDir(C.maps_directory) not yet :(
	end

	Global.blt_checked_updates = Global.blt_checked_updates or {}

	rawset(_G, C.logs_path_global, C.mods_directory .. C.logs_directory)
	rawset(_G, C.save_path_global, C.mods_directory .. C.saves_directory)

	-- Initialization functions
	self.Logs:CleanLogs()
	self.Mods:SetModsList(self:ProcessModsList(self:FindMods()))
	-- Some backwards compatibility for v1 mods
	
	local bltconfig = self.Mods:GetModByName("Raid WW2 BLT") --find a better way to do this
	if bltconfig then
		self._mod = bltconfig
		table.merge(self, bltconfig)
	end

	self.Dialogs = BLTMenuDialogManager:new()
	self.ModsMenu = BLTModsMenu:new()

	_G.LuaModManager = {}
	_G.LuaModManager.Constants = C
	_G.LuaModManager.Mods = {} -- No mods are available via old api
end

function BLT:GetVersion()
	return self.version
end

function BLT:GetOS()
	return os.getenv("HOME") == nil and "windows" or "linux"
end

function BLT:RunHookTable(hooks_table, path)
	if not hooks_table or not hooks_table[path] then
		return false
	end
	for i, hook_data in pairs( hooks_table[path] ) do
		self:RunHookFile( path, hook_data )
	end
end

function BLT:RunHookFile(path, hook_data)
	rawset( _G, BLTModManager.Constants.required_script_global, path or false )
	rawset( _G, BLTModManager.Constants.mod_path_global, hook_data.mod:GetPath() or false )
	dofile( hook_data.mod:GetPath() .. hook_data.script )
end

function BLT:OverrideRequire()

	if self.require then
		return false
	end

	-- Cache original require function
	self.require = self.require or _G.require

	-- Override require function to run hooks

	self.new_require = function( ... )
		local args = { ... }
		local path = args[1]
		local path_lower = path:lower()
		local require_result = nil

		self:RunHookTable( self.hook_tables.pre, path_lower )
		require_result = self.require( ... )
		self:RunHookTable( self.hook_tables.post, path_lower )

		for k, v in ipairs( self.hook_tables.wildcards ) do
			self:RunHookFile( path, v.mod_path, v.script )
		end

		return require_result
	end

	-- Load mods in first require(due to how the engine loads stuff that we need), then return the require to new_require.
	_G.require = function( ... )
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
			local mod_defintion = mod_path .. "mod.txt"
			local is_xml
			if not FileIO:Exists(mod_defintion) then
				mod_defintion = mod_path .. "mod.xml"
				is_xml = true
			end

			-- Attempt to read the mod defintion file
			local file = io.open(mod_defintion)
			if file then
				log("[BLT] Loading mod: " .. tostring(directory))
				-- Read the file contents
				local mod_content = FileIO:ConvertScriptData(file:read("*all"), is_xml and "custom_xml" or "json")
				file:close()
				-- Create a BLT mod from the loaded data
				if mod_content then
					if is_xml then
						table.insert(mods_list, BLTModExtended:new(path, directory, mod_content, true))
					else
						table.insert(mods_list, BLTMod:new(path, directory, mod_content))
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