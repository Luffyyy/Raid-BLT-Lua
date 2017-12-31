
BLTModManager = BLTModManager or class()
function BLTModManager:init()
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
		local data = {mod = mod, script = hook_file}
		if req_script ~= "*" then
			table.insert(dest_tbl[req_script], data)
		else
			table.insert(BLT.hook_tables.wildcards, data)
		end
	else
		mod = mod or BLT
        mod:log("[ERROR] Hook file not readable by the lua state! File: %s", hook_file)
    end
end

--------------------------------------------------------------------------------
-- Saving and Loading

function BLTModManager:Load()
	-- Setup mods
	for index, mod in ipairs(self.mods) do
		mod:Setup()
	end

	-- Call load hook
	Hooks:Call("BLTOnLoadData", saved_data)
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
BLTModManager.Constants.mod_global = "CurrentMod"
BLTModManager.Constants.logs_path_global = "LogsPath"
BLTModManager.Constants.save_path_global = "SavePath"
BLTModManager.Constants.BLTOptions = "blt_options"
BLTModManager.Constants.BLTKeybinds = "blt_keybinds"
function BLTModManager.Constants:ModsDirectory()
	return self.mods_directory
end

function BLTModManager.Constants:BaseDirectory()
	return self.mods_directory .. self.lua_base_directory
end

function BLTModManager.Constants:DownloadsDirectory()
	return self.mods_directory .. self.downloads_directory
end

function BLTModManager.Constants:LogsDirectory()
	return self.mods_directory .. self.logs_directory
end

function BLTModManager.Constants:SavesDirectory()
	return self.mods_directory .. self.saves_directory
end

function BLTModManager.Constants:ModManagerSaveFile()
	return self:SavesDirectory() .. "blt_data.txt"
end