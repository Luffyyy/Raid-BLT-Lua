-- BLT Mod / PD2 mod format.
BLTMod = BLTMod or class()
BLTMod.enabled = true
BLTMod._enabled = true
BLTMod.path = ""
BLTMod.id = "blt_mod"
BLTMod.name = "None"
BLTMod.desc = "Empty"
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
	self:InitParams(path, ident, data)

    -- Parse color info
    -- Stored as a table until first requested due to Color not existing yet
    if data.color and type(data.color) == "string" then
        local colors = string.split(data.color, " ")
        local cp = {}
        local divisor = 1
        for i = 1, 3 do
            local c = tonumber(colors[i] or 0)
            table.insert(cp, c)
            if c > 1 then
                divisor = 255
            end
        end
        if divisor > 1 then
            for i, val in ipairs(cp) do
                cp[i] = val / divisor
            end
        end
        self.color = cp
    end

	-- Updates data
	if self._config.updates then
		self._modules = {}
		for _, data in ipairs(self._config.updates) do
			local update = UpdatesModule:new(self, {
				provider = "paydaymods",
				id = data.identifier,
				important = data.critical,
				hash_file = data.hash_file,
				manual_check = data.disallow_update, -- I think
				install_directory = data.load_dir or "mods/",
				folder_name = data.install_folder
			})
			table.insert(self._modules, update)
		end
	end
end

function BLTMod:InitParams(path, ident, data)
    self._config = data
    self.id = ident
    self.load_dir = path
	self.path = string.format("%s%s/", path, ident)
	self.save_path = data.save_path or "saves/"
    self.name = data.name or self.id
    self.desc = data.description or BLTMod.desc
    self.version = data.version
    self.min_blt_version = data.min_blt_version
    self.author = data.author or BLTMod.author
    self.contact = data.contact or BLTMod.contact
    self.priority = tonumber(data.priority) or 0
    self.dependencies = data.dependencies or {}
    self.image_path = data.image or nil
	self.registered_hooks = {post = {}, pre = {}, wildcards = {}}
end

function BLTMod:SetupCheck()
    -- Check mod is compatible with this version of the BLT
    local disabled_mods = BLT.Options:GetValue("DisabledMods")

    local mod_blt_version = self:GetMinBLTVersion()
    mod_blt_version = mod_blt_version and tonumber(mod_blt_version) or nil
    if mod_blt_version and mod_blt_version > BLT:GetVersion() then
        self._blt_outdated = true
        table.insert(self._errors, {"blt_mod_blt_outdated", math.round_with_precision(mod_blt_version, 4)})
    end

    -- Check dependencies are installed for this mod
   	self:AreDependenciesAvailable(true)
	
	self:SetEnabled(not self:Errors() and not disabled_mods[self.path])
end

function BLTMod:Setup()
    print("[BLT] Setting up mod: ", self:GetId())

    self:SetupCheck()
    if not self:IsEnabled() then
        return
    end

    -- Hooks data
    self:AddHooks("hooks", BLT.hook_tables.post, BLT.hook_tables.wildcards)
    self:AddHooks("pre_hooks", BLT.hook_tables.pre, BLT.hook_tables.wildcards)

    -- Keybinds
    if BLT.Keybinds then
        for i, keybind_data in ipairs(self._config.keybinds or {}) do
            BLT.Keybinds:register_keybind(self, keybind_data)
        end
    end

    -- Persist Scripts
    for i, persist_data in ipairs(self._config.persist_scripts or {}) do
        if persist_data and persist_data.global and persist_data.script_path then
            self:AddPersistScript(persist_data.global, persist_data.script_path)
        end
    end
end

function BLTMod:AddHooks(data_key, destination, wildcards_destination)
    local hooks = self._config[data_key] or {}
    local path = Path:Combine(self:GetPath(), hooks.directory)
	for i, hook in ipairs(hooks) do
		local source_file = hook.source_file or hook.hook_id
		local script = hook.file or hook.script_path
		BLT.Mods:RegisterHook(source_file, path, script, hook.type, self)
		if source_file == "*" then
			table.insert(self.registered_hooks.wildcards, script)
		elseif hook.type == "pre" then
			table.insert(self.registered_hooks.pre, {source_file, script})
		else
			table.insert(self.registered_hooks.post, {source_file, script})
		end
	end
end

function BLTMod:AddPersistScript(global, file)
    self._persists = self._persists or {}
    table.insert(self._persists, {global = global, file = file})
end

function BLTMod:GetHooks()
    return self.registered_hooks.post
end

function BLTMod:GetPreHooks()
    return self.registered_hooks.pre_hooks
end

function BLTMod:GetWildcards()
    return self.registered_hooks.wildcards
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

function BLTMod:SetEnabled(enable, force)
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

function BLTMod:GetVersion(noRounding)
    if tonumber(self.version) and not noRounding then
        return math.round_with_precision(self.version, 4) --fixes xml fuckup with numbers.
    else
        return self.version
    end
end

function BLTMod:GetMinBLTVersion()
    return math.round_with_precision(self.min_blt_version or 1, 4)
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
    if SystemFS:exists(Application:nice_path(self:GetModImagePath(), true)) then
        local new_textures = {}
        local type_texture_id = Idstring("texture")
        local path = self:GetModImagePath()
        local texture_id = Idstring(path)

        DB:create_entry(type_texture_id, texture_id, path)
        table.insert(new_textures, texture_id)
        Application:reload_textures(new_textures)

        return texture_id
    else
        log("[Error] Mod image at path does not exist! " .. tostring(self:GetModImagePath()))
        return nil
    end
end

function BLTMod:clbk_check_for_updates(update, required, reason)
    self._update_cache = self._update_cache or {}
    self._update_cache[update:GetId()] = {
        requires_update = required,
        reason = reason,
        update = update
    }

    if self._update_cache.clbk and not self:IsCheckingForUpdates() then
        local clbk = self._update_cache.clbk
        self._update_cache.clbk = nil
        clbk(self._update_cache)
    end
end

function BLTMod:CannotBeDisabled()
    return NotNil(self.cannot_be_disabled, false)
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

function BLTMod:AreDependenciesAvailable(pick_errors)
	if not BLT.Options then
		return true
	end

    local dep_mods = {}
	local available = true
    local disabled_mods = BLT.Options:GetValue("DisabledMods")

	-- Iterate all mods and updates to find dependencies, store any that are missing
    local dependencies = self:GetDependencies()
    for _, mod in pairs(BLT.Mods:Mods()) do
        local name = mod:GetName()
        if table.contains(dependencies, name) then
			dep_mods[name] = mod
        end
    end

    for _, id in ipairs(dependencies) do
        local mod = dep_mods[id]
		if mod then
			if mod:CanBeDisabled() and disabled_mods[mod:GetPath()] and pick_errors then
				table.insert(self._errors, {"blt_mod_dependency_disabled", id})
				available = false
			end
		else
			table.insert(self._errors, {"blt_mod_missing_dependency", id})
			available = false
		end
    end

    return available
end

function BLTMod:GetDeveloperInfo()
    local str = ""
    local append = function(...)
        for i, s in ipairs({...}) do
            str = str .. (i > 1 and "    " or "") .. tostring(s)
        end
        str = str .. "\n"
	end
	

    local hooks = self:GetHooks() or {}
    local prehooks = self:GetPreHooks() or {}
    local wildcards = self:GetWildcards() or {}
    local persists = self:GetPersistScripts() or {}
    local version = self:GetVersion()

	if #self._errors > 0 then
		append("Failed to load!")
		append("", "Errors:")
        for _, err in pairs(self._errors) do
            local param = type(err) == "table" and err[2] or nil
            err = param and err[1] or err
			append("", "", tostring(managers.localization:text(err, {param = param})))
        end
    end
    
    append("Name:", self:GetName())
    append("Path:", self:GetPath())
    append("Description:", self:GetDescription())
    append("Author:", self:GetAuthor())
    append("Contact:", self:GetContact())
    append("Path:", self:GetPath())
	append("Load Priority:", self:GetPriority())

	if version then
		append("Version:", version)
	end
    local min = self:GetMinBLTVersion()
    if min then
        append("Minimum BLT-Version:", min)
    end

	if self:CannotBeDisabled() then
    	append("Cannot be disabled")
	end
	
	if self._modules then
		for _, module in pairs(self._modules) do
			if module.GetInfo then
				module:GetInfo(append)
			end
		end
	end

    if #hooks == 0 then
        append("Hooks: None")
    else
        append("Hooks:")
        for _, hook in ipairs(hooks) do
            append("", tostring(hook[1]), "->", tostring(hook[2]))
        end
    end
	for _, hook in ipairs(wildcards) do
		append("", "* ->", tostring(hook))
	end

    if #prehooks == 0 then
        append("Pre-Hooks: None")
    else
        append("Pre-Hooks:")
        for _, hook in ipairs(prehooks) do
            append("", tostring(hook[1]), "->", tostring(hook[2]))
        end
    end
	
    if table.size(persists) < 1 then
        append("Persisent Scripts: None")
    else
        append("Persisent Scripts:")
        for _, script in ipairs(persists) do
            append("", script.global, "->", script.file)
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
    if str == "self" then
        return self
    end

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
