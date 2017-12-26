
BLTModManager = BLTModManager or class()
function BLTModManager:init()
	Hooks:Register("BLTOnSaveData")
	Hooks:Register("BLTOnLoadData")
	self.mods = {}
end

function BLTModManager:Mods()
	return self.mods
end

function BLTModManager:GetMod(id)
	for _, mod in ipairs(self:Mods()) do
		if mod:GetId() == id then
			return mod
		end
	end
end

function BLTModManager:GetModByName(name)
	for _, mod in ipairs(self:Mods()) do
		if mod:GetName() == name then
			return mod
		end
	end
end

function BLTModManager:GetModOwnerOfFile(file)
	for _, mod in pairs(self:Mods()) do
		if string.find(file, mod:GetPath()) == 1 then
			return mod
		end
	end
end

function BLTModManager:SetModsList(mods_list)
	self.mods = mods_list
	self:Load()
end

function BLTModManager:IsExcludedDirectory(directory)
	return BLTModManager.Constants.ExcludedModDirectories[directory]
end

function BLTModManager:RegisterHook(source_file, path, file, type, mod)
    path = path .. "/"
    local hook_file = Path:Combine(path, file)
    local dest_tbl = type == "pre" and BLT.hook_tables.pre or BLT.hook_tables.post
    if dest_tbl and FileIO:Exists(hook_file) then
        local req_script = source_file:lower()

		dest_tbl[req_script] = dest_tbl[req_script] or {}
		local data = {mod = mod, script = file}
		if req_script ~= "*" then
			table.insert(dest_tbl[req_script], data)
		else
			table.insert(BLT.hook_tables.wildcards, data)
		end
    else
        BLT:log("[ERROR] Hook file not readable by the lua state! File: %s", file)
    end
end

--------------------------------------------------------------------------------
-- Saving and Loading

function BLTModManager:Load()
	-- If we have old save files, then load their data
	if self:HasOldSaveFiles() then
		self:ConvertOldSaveFiles()
	end

	-- Load data
	local saved_data = io.load_as_json(BLTModManager.Constants:ModManagerSaveFile()) or {}

	-- Process mods
	if saved_data["mods"] then
		for index, mod in ipairs(self.mods) do
			if saved_data["mods"][mod:GetId()] then
				local data = saved_data["mods"][mod:GetId()]

				mod:SetEnabled(data["enabled"], true)
				mod:SetSafeModeEnabled(data["safe"])
			end
		end
	end

	-- Setup mods
	for index, mod in ipairs( self.mods ) do
		mod:Setup()
	end

	-- Call load hook
	Hooks:Call("BLTOnLoadData", saved_data)
end

function BLTModManager:HasOldSaveFiles()
	return io.file_is_readable( BLTModManager.Constants:OldModManagerSaveFile() ) or
			io.file_is_readable( BLTModManager.Constants:OldModManagerKeybindsFile() ) or
			io.file_is_readable( BLTModManager.Constants:OldModManagerUpdatesFile() )
end

function BLTModManager:ConvertOldSaveFiles()

	print("[BLT] Converting old save data files to new format...")

	-- Load old files
	local enabled_mods = io.load_as_json( BLTModManager.Constants:OldModManagerSaveFile() )
	if enabled_mods == nil or type(enabled_mods) ~= "table" then
		enabled_mods = {}
	end

	-- Convert enabled mods data
	for mod_id, enabled in pairs( enabled_mods ) do
		for index, mod in ipairs( self.mods ) do
			if mod_id == mod:GetId() then
				mod:SetEnabled( enabled )
				break
			end
		end
	end

	-- Only remove old files if we sucessfully save the new data
	if self:Save() then
		os.remove( BLTModManager.Constants:OldModManagerSaveFile() )
		os.remove( BLTModManager.Constants:OldModManagerKeybindsFile() )
		os.remove( BLTModManager.Constants:OldModManagerUpdatesFile() )
		print("[BLT] ...Success!")
	else
		print("[BLT] ...Failed! Will try again at a later time!")
	end

end

function BLTModManager:Save()
	log("[BLT] Performing save...")
	Hooks:Call("BLTOnSaveData", save_data)
end

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
BLTModManager.Constants = {
	mods_directory = "mods/",
	mod_overrides_directory = "assets/mod_overrides/",
	maps_directory = "maps/",
	lua_base_directory = "base/",
	downloads_directory = "downloads/",
	logs_directory = "logs/",
	saves_directory = "saves/",
}
BLTModManager.Constants.ExcludedModDirectories = {
	logs = true,
	saves = true,
	downloads = true,
	_temp = true,
}
BLTModManager.Constants.required_script_global = "RequiredScript"
BLTModManager.Constants.mod_path_global = "ModPath"
BLTModManager.Constants.logs_path_global = "LogsPath"
BLTModManager.Constants.save_path_global = "SavePath"

BLTModManager.Constants.lua_mods_menu_id = "blt_mods_new"
BLTModManager.Constants.lua_mod_options_menu_id = "blt_options"

function BLTModManager.Constants:ModsDirectory()
	return self["mods_directory"]
end

function BLTModManager.Constants:BaseDirectory()
	return self["mods_directory"] .. self["lua_base_directory"]
end

function BLTModManager.Constants:DownloadsDirectory()
	return self["mods_directory"] .. self["downloads_directory"]
end

function BLTModManager.Constants:LogsDirectory()
	return self["mods_directory"] .. self["logs_directory"]
end

function BLTModManager.Constants:SavesDirectory()
	return self["mods_directory"] .. self["saves_directory"]
end

function BLTModManager.Constants:ModManagerSaveFile()
	return self:SavesDirectory() .. "blt_data.txt"
end

function BLTModManager.Constants:OldModManagerSaveFile()
	return self:SavesDirectory() .. "mod_manager.txt"
end

function BLTModManager.Constants:OldModManagerKeybindsFile()
	return self:SavesDirectory() .. "mod_keybinds.txt"
end

function BLTModManager.Constants:OldModManagerUpdatesFile()
	return self:SavesDirectory() .. "mod_updates.txt"
end

function BLTModManager.Constants:LuaModsMenuID()
	return self["lua_mods_menu_id"]
end

function BLTModManager.Constants:LuaModOptionsMenuID()
	return self["lua_mod_options_menu_id"]
end

-- Backwards compatibility
BLTModManager.Constants._lua_mods_menu_id = BLTModManager.Constants.lua_mods_menu_id
BLTModManager.Constants._lua_mod_options_menu_id = BLTModManager.Constants.lua_mod_options_menu_id