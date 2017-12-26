
-- BLT Mod / PD2 mod format.
BLTMod = BLTMod or class()
BLTMod.enabled = true
BLTMod._enabled = true
BLTMod.path = ""
BLTMod.id = "blt_mod"
BLTMod.name = "Unnamed BLT Mod"
BLTMod.desc = "No description."
BLTMod.version = "1.0"
BLTMod.author = "Unknown"
BLTMod.contact = "N/A"
BLTMod.priority = 0

function BLTMod:init(path, ident, data)	
	if not ident then
		self:log("BLTMods can not be created without a mod identifier!")
		return
	end
	if not data then
		self:log("BLTMods can not be created without mod data!")
		return
	end
	
	self._errors = {}

	-- Mod information
	self._config = data
	self.id = ident
	self.load_dir = path
	self.path = string.format("%s%s/", path, ident)
	self.name = data["name"] or "Error: No Name!"
	self.desc = data["description"] or self.desc
	self.version = data["version"] or self.version
	self.blt_version = data["blt_version"] or "unknown"
	self.author = data["author"] or self.author
	self.contact = data["contact"] or self.contact
	self.priority = tonumber(data["priority"]) or 0
	self.dependencies = data["dependencies"] or {}
	self.image_path = data["image"] or nil
	self.disable_safe_mode = data["disable_safe_mode"] or false
	self.undisablable = data["undisablable"] or false
	self.safe_mode = true

	-- Parse color info
	-- Stored as a table until first requested due to Color not existing yet
	if data["color"] and type(data["color"]) == "string" then
		local colors = string.split( data["color"], ' ' )
		local cp = {}
		local divisor = 1
		for i = 1, 3 do
			local c = tonumber(colors[i] or 0)
			table.insert( cp, c )
			if c > 1 then
				divisor = 255
			end
		end
		if divisor > 1 then
			for i, val in ipairs( cp ) do
				cp[i] = val / divisor
			end
		end
		self.color = cp
	end

	-- Updates data
	for _, data in ipairs(self._config["updates"] or {}) do
		UpdatesModule:new(self, {
			provider = "paydaymods",
			id = data.identifier,
			important = data.critical,
			hash_file = data.hash_file,
			manual_check = data.disallow_update, -- I think
			install_directory = data.load_dir or "mods/",
			folder_names = {data.install_folder}
		})
	end
end

function BLTMod:SetupCheck()
	-- Check mod is compatible with this version of the BLT
	local mod_blt_version = self:GetMinBLTVersion()
	mod_blt_version = mod_blt_version and tonumber(mod_blt_version) or nil
	if mod_blt_version and mod_blt_version > BLT:GetVersion() then
		self._blt_outdated = true
		table.insert( self._errors, "blt_outdated" )
	end

	-- Check dependencies are installed for this mod
	if not self:AreDependenciesInstalled() then
		table.insert( self._errors, "blt_mod_missing_dependencies" )
		return
	end
end

function BLTMod:Setup()
	print("[BLT] Setting up mod: ", self:GetId())

	self:SetupCheck()

	-- Hooks data
	self.hooks = {}
	self:AddHooks("hooks", BLT.hook_tables.post, BLT.hook_tables.wildcards)
	self:AddHooks("pre_hooks", BLT.hook_tables.pre, BLT.hook_tables.wildcards)

	-- Keybinds
	if BLT.Keybinds then
		for i, keybind_data in ipairs(self._config["keybinds"] or {}) do
			BLT.Keybinds:register_keybind_json(self, keybind_data)
		end
	end

	-- Persist Scripts
	for i, persist_data in ipairs(self._config["persist_scripts"] or {}) do
		if persist_data and persist_data["global"] and persist_data["script_path"] then
			self:AddPersistScript(persist_data["global"], persist_data["script_path"])
		end
	end
end

function BLTMod:AddHooks( data_key, destination, wildcards_destination )

	self.hooks[data_key] = {}

	for i, hook_data in ipairs( self._config[data_key] or {} ) do

		local hook_id = hook_data["hook_id"] and hook_data["hook_id"]:lower()
		local script = hook_data["script_path"]

		-- Add hook to info table
		local unique = true
		for i, hook in ipairs( self.hooks[data_key] ) do
			if hook == hook_id then
				unique = false
				break
			end
		end
		if unique then
			table.insert( self.hooks[data_key], hook_id )
		end

		-- Add hook to hooks tables
		if hook_id and script and self:IsEnabled() then

			local data = {
				mod = self,
				script = script
			}

			if hook_id ~= "*" then
				destination[ hook_id ] = destination[ hook_id ] or {}
				table.insert( destination[ hook_id ], data )
			else
				table.insert( wildcards_destination, data )
			end

		end

	end
end

function BLTMod:AddPersistScript( global, file )
	self._persists = self._persists or {}
	table.insert( self._persists, {
		global = global,
		file = file
	} )
end

function BLTMod:GetHooks()
	return (self.hooks or {})["hooks"]
end

function BLTMod:GetPreHooks()
	return (self.hooks or {})["pre_hooks"]
end

function BLTMod:GetPersistScripts()
	return self._persists or {}
end

function BLTMod:Errors()
	if #self._errors > 0 then
		return self._errors
	else
		return false
	end
end

function BLTMod:log(str, ...)
	log("[" .. self.name .. "] " .. string.format(str, ...))
end

function BLTMod:LastError()
	local n = #self._errors
	if n > 0 then
		return self._errors[n]
	else
		return false
	end
end

function BLTMod:IsEnabled()
	return self.enabled
end

function BLTMod:WasEnabledAtStart()
	return self._enabled
end

function BLTMod:CanBeDisabled()
	return self.id ~= "base"
end

function BLTMod:SetEnabled( enable, force )
	if not self:CanBeDisabled() then
		-- Base mod must always be enabled
		enable = true
	end
	self.enabled = enable
	if force then
		self._enabled = enable
	end
end

function BLTMod:GetPath()
	return self.path
end

function BLTMod:GetConfig()
	return self._config
end

function BLTMod:GetId()
	return self.id
end

function BLTMod:GetName()
	return self.name
end

function BLTMod:GetDescription()
	return self.desc
end

function BLTMod:GetVersion()
	return self.version
end

function BLTMod:GetMinBLTVersion()
	return self.min_blt_version
end

function BLTMod:GetAuthor()
	return self.author
end

function BLTMod:GetContact()
	return self.contact
end

function BLTMod:GetPriority()
	return self.priority
end

function BLTMod:GetColor()
	if not self.color then
		return tweak_data.gui.colors.raid_list_background
	end
	if type(self.color) == "table" then
		self.color = Color(unpack(self.color))
	end
	return self.color
end

function BLTMod:HasModImage()
	return self._config.image ~= nil
end

function BLTMod:GetModImagePath()
	return self:GetPath() .. tostring(self._config.image)
end

function BLTMod:GetModImage()
	if not DB or not DB.create_entry or not self:HasModImage() then
		return nil
	end

	-- Check if the file exists on disk and generate if it does
	if SystemFS:exists( Application:nice_path( self:GetModImagePath(), true ) ) then
		
		local new_textures = {}
		local type_texture_id = Idstring( "texture" )
		local path = self:GetModImagePath()
		local texture_id = Idstring(path)

		DB:create_entry( type_texture_id, texture_id, path )
		table.insert( new_textures, texture_id )
		Application:reload_textures( new_textures )

		return texture_id

	else
		log("[Error] Mod image at path does not exist! " .. tostring(self:GetModImagePath()))
		return nil
	end

end

function BLTMod:clbk_check_for_updates( update, required, reason )

	self._update_cache = self._update_cache or {}
	self._update_cache[ update:GetId() ] = {
		requires_update = required,
		reason = reason,
		update = update
	}

	if self._update_cache.clbk and not self:IsCheckingForUpdates() then
		local clbk = self._update_cache.clbk
		self._update_cache.clbk = nil
		clbk( self._update_cache )
	end

end

function BLTMod:IsSafeModeEnabled()
	return self.safe_mode
end

function BLTMod:SetSafeModeEnabled( enabled )
	if enabled == nil then
		enabled = true
	end
	if self:DisableSafeMode() then
		enabled = false
	end
	self.safe_mode = enabled
end

function BLTMod:DisableSafeMode()
	if self:IsUndisablable() then
		return true
	end
	return self.disable_safe_mode
end

function BLTMod:IsUndisablable()
	return self.undisablable or false
end

function BLTMod:HasDependencies()
	return table.size(self.dependencies) > 0
end

function BLTMod:GetDependencies()
	return self.dependencies or {}
end

function BLTMod:GetMissingDependencies()
	return self.missing_dependencies or {}
end

function BLTMod:GetDisabledDependencies()
	return self.disabled_dependencies or {}
end

function BLTMod:AreDependenciesInstalled()
	local installed = false
	local dep_mods = {}

	self.missing_dependencies = {}
	self.disabled_dependencies = {}
	
	-- Iterate all mods and updates to find dependencies, store any that are missing
	local dependencies = self:GetDependencies()
	for _, mod in pairs(BLT.Mods:Mods()) do
		local name = mod:GetName()
		if table.contains(dependencies, name) then
			if mod:IsEnabled() then
				dep_mods[name] = mod
				installed = true
			else
				table.insert(self.disabled_dependencies, mod)
				table.insert(self._errors, "blt_mod_dependency_disabled")
			end
			break
		end
	end
	
	for _, id in pairs(self:GetDependencies()) do
		if not dep_mods[id] then
			local dependency = BLTModDependency:new(self, id)
			table.insert(self.missing_dependencies, dependency)
		end
	end

	return installed
end

--TODO: move this to mods menu
function BLTMod:GetDeveloperInfo()

	local str = ""
	local append = function( ... )
		for i, s in ipairs( {...} ) do
			str = str .. (i > 1 and "    " or "") .. tostring(s)
		end
		str = str .. "\n"
	end

	local hooks = self:GetHooks() or {}
	local prehooks = self:GetPreHooks() or {}
	local persists = self:GetPersistScripts() or {}

	append( "Path:", self:GetPath() )
	append( "Load Priority:", self:GetPriority() )
	append( "Version:", self:GetVersion() )
	local min = self:GetMinBLTVersion()
	if min then
		append( "Minimum BLT-Version:", min)
	end

	append( "Disablable:", not self:IsUndisablable() )
	append( "Allow Safe Mode:", not self:DisableSafeMode() )

	if table.size( hooks ) < 1 then
		append( "No Hooks" )
	else
		append( "Hooks:" )
		for _, hook in ipairs( hooks ) do
			append( "", tostring(hook) )
		end
	end

	if table.size( prehooks ) < 1 then
		append( "No Pre-Hooks" )
	else
		append( "Pre-Hooks:" )
		for _, hook in ipairs( prehooks ) do
			append( "", tostring(hook) )
		end
	end

	if table.size( persists ) < 1 then
		append( "No Persisent Scripts" )
	else
		append( "Persisent Scripts:" )
		for _, script in ipairs( persists ) do
			append( "", script.global, "->", script.file )
		end
	end

	return str
end

function BLTMod:GetRealFilePath(path, lookup_tbl)
    if string.find(path, "%$") then
        return string.gsub(path, "%$(%w+)%$", lookup_tbl or self)
    else
        return path
    end
end

function BLTMod:StringToTable(str)
    if str == "self" then return self end

    if (string.find(str, "$")) then
        str = string.gsub(str, "%$(%w+)%$", self)
    end

    local global_tbl
    local self_search = "self."
    if string.begins(str, self_search) then
        str = string.sub(str, #self_search + 1, #str)
        global_tbl = self
    end

    return Utils:StringToTable(str, global_tbl)
end

function BLTMod:StringToCallback(str, self_tbl)
    local split = string.split(str, ":")

    local func_name = table.remove(split)

    local global_tbl_name = split[1]

    local global_tbl = self:StringToTable(global_tbl_name)
    if global_tbl then
        return callback(self_tbl or global_tbl, global_tbl, func_name)
    else
        return nil
    end
end

function BLTMod:__tostring()
	return string.format("[BLTMod %s (%s)]", self:GetName(), self:GetId())
end