
-- BLT Mod / New mod format
BLTModExtended = BLTModExtended or class(BLTMod)
BLTModExtended.enabled = true
BLTModExtended._enabled = true
BLTModExtended.path = ""
BLTModExtended.id = "blt_mod"
BLTModExtended.name = "Unnamed BLT Mod"
BLTModExtended.desc = "No description."
BLTModExtended.version = "1.0"
BLTModExtended.author = "Unknown"
BLTModExtended.contact = "N/A"
BLTModExtended.priority = 0

function BLTModExtended:init(path, ident, data, post_init)
	if not ident then
		self:log("BLTModExtendeds can not be created without a mod identifier!")
		return
	end
	if not data then
		self:log("BLTModExtendeds can not be created without mod data!")
		return
	end

	self._errors = {}

	-- Mod information
	self._config = data
	self.id = ident
	self.load_dir = path
	self.path = string.format("%s%s/", path, ident)
	self.save_path = data.save_path or "saves/"
	self.name = data.name or self.id or "Error: No Name!"
	self.desc = data.description or self.desc
	self.version = data.version or self.version
	self.min_blt_version = data.min_blt_version
	self.author = data.author or self.author
	self.contact = data.contact or self.contact
	self.priority = tonumber(data.priority) or 0
	self.dependencies = data.dependencies or {}
	self.disable_safe_mode = data.disable_safe_mode or false
	self.undisablable = data.undisablable or false
	self.safe_mode = true

	self._auto_post_init = data.post_init or post_init

	self.color = data.color

	self:InitModules()
end

function BLTModExtended:InitModules()
    if self.modules_initialized then
        return
    end

    self._modules = {}
    for i, module_tbl in ipairs(self._config) do
        if type(module_tbl) == "table" then
            local meta = module_tbl._meta
            local node_class = BLT.Modules[meta:lower()]
            if not node_class and module_tbl.force_search then
                node_class = CoreSerialize.string_to_classtable(module_tbl._meta)
            end
            if node_class then
                if self:IsEnabled() or node_class._always_enabled then
                    local success, node_obj, valid = pcall(function() return node_class:new(self, module_tbl) end)
                    if success then
                        if valid == false then
                            self:log("Module with name %s does not contain a valid config. See above for details", node_obj._name)
                        else
                            if not node_obj._loose or node_obj._name ~= node_obj.type_name then
                                if self[node_obj._name] then
                                    self:log("The name of module: %s already exists in the mod table, please make sure this is a unique name!", node_obj._name)
                                end

                                self[node_obj._name] = node_obj
                            end
                            table.insert(self._modules, node_obj)
                        end
                    else
                        self:log("[ERROR] An error occured on initilization of module: %s. Error:\n%s", module_tbl._meta, tostring(node_obj))
                        table.insert(self._errors, "blt_module_failed_load")
                    end
                end
            elseif not self._config.ignore_errors then
                self:log("[ERROR] Unable to find module with key %s", module_tbl._meta)
            end
        end
    end

    if self._auto_post_init or self._config.post_init then
        self:PostInitModules()
    end
    self.modules_initialized = true
end


function BLTModExtended:PostInitModules(ignored_modules)
    for _, module in pairs(self._modules) do
        if (not ignored_modules or not table.contains(ignored_modules, module._name)) then
            local success, err = pcall(function() module:post_init() end)
            if not success then
                self:log("[ERROR] An error occured on the post initialization of %s. Error:\n%s", module._name, tostring(err))
            end
        end
    end
end

function BLTModExtended:Setup()
	print("[BLT] Setting up mod: ", self:GetId())
    self:SetupCheck()
end

function BLTModExtended:GetAllHooks()
	return self.hooks and self.hooks.registered or {}
end

function BLTModExtended:GetHooks()
	return self:GetAllHooks().post or {}
end

function BLTModExtended:GetPreHooks()
	return self:GetAllHooks().pre or {}
end

function BLTModExtended:GetDeveloperInfo()

	local str = ""
	local append = function( ... )
		for i, s in ipairs( {...} ) do
			str = str .. (i > 1 and "    " or "") .. tostring(s)
		end
		str = str .. "\n"
	end

	local hooks = self:GetHooks() or {}
	local prehooks = self:GetPreHooks() or {}
	--Show classes instead
	local persists = {} -- self:GetPersistScripts() or {}

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
			append( "", tostring(hook[1]), "->", tostring(hook[2]))
		end
	end

	if table.size(prehooks) < 1 then
		append("No Pre-Hooks")
	else
		append("Pre-Hooks:")
		for _, hook in ipairs(prehooks) do
			append( "", tostring(hook[1]), "->", tostring(hook[2]))
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