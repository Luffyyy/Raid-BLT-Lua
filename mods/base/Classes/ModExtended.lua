
-- BLT Mod / New mod format
BLTModExtended = BLTModExtended or class(BLTMod)

local BLTModExtended = BLTModExtended
BLTModExtended.enabled = true
BLTModExtended._enabled = true
BLTModExtended.path = ""
BLTModExtended.id = "blt_mod"
BLTModExtended.name = "Unnamed BLT Mod"
BLTModExtended.desc = "No description."
BLTModExtended.author = "Unknown"
BLTModExtended.contact = "N/A"
BLTModExtended.priority = 0

function BLTModExtended:init(path, ident, data, post_init)
	-- Use most recent log data
	self.LOG_LEVEL = BLT.LOG_LEVEL
	self.LogPrefixes = BLT.LogPrefixes

	-- Check module data
	if not ident then
		self:Log(LogLevel.ERROR, "BLTModSetup", "BLTMods can not be created without a mod identifier!")
		return
	end
	if not data then
		self:Log(LogLevel.ERROR, "BLTModSetup", "BLTMods can not be created without mod data!")
		return
	end

	self._errors = {}

	-- Mod information
	self:InitParams(path, ident, data)

	self._early_init = data.early_init
	self._auto_post_init = NotNil(data.auto_post_init, post_init)

	self.color = data.color
end

function BLTModExtended:PostInit()
    if self._early_init then
        self:InitModules()
    end
end

function BLTModExtended:InitModules()
    if self.modules_initialized then
        return
    end

    self._modules = {}
    for i, module_tbl in ipairs(self._config) do
        if type(module_tbl) == "table" then
            local meta = module_tbl._meta
            local node_class = BLT.Modules[string.CamelCase(meta)]
            if not node_class and module_tbl.force_search then
                node_class = CoreSerialize.string_to_classtable(module_tbl._meta)
            end
            if node_class then
                if self:IsEnabled() or node_class._always_enabled then
                    local success, node_obj, valid = pcall(function() return node_class:new(self, module_tbl) end)
                    if success then
                        if valid == false then
                            self:LogF(LogLevel.WARN, "BLTModSetup", "Module with name '%s' does not contain a valid config. See above for details.", tostring(node_obj._name))
                        else
                            if not node_obj._loose or node_obj._name ~= node_obj.type_name then
                                if self[node_obj._name] then
                                    self:LogF(LogLevel.WARN, "BLTModSetup", "A module named '%s' already exists in the mod table, please make sure this is a unique name!", tostring(node_obj._name))
                                end

                                self[node_obj._name] = node_obj
                            end
                            table.insert(self._modules, node_obj)
                        end
                    else
                        self:LogF(LogLevel.ERROR, "BLTModSetup", "An error occured on initilization of module: %s. Error:\n%s", tostring(module_tbl._meta), tostring(node_obj))
                        table.insert(self._errors, "blt_module_failed_load")
                    end
                end
            elseif not self._config.ignore_errors then
                self:LogF(LogLevel.ERROR, "BLTModSetup", "Unable to find module with key '%s'.", tostring(module_tbl._meta))
            end
        end
    end
    if self._auto_post_init then
        self:PostInitModules()
    end
    self.modules_initialized = true
end


function BLTModExtended:PostInitModules(ignored_modules)
	local data = self:GetConfig()
	if data.global_key then
		self.global = data.global_key
		if _G[self.global] then
			if data.merge_global then
				table.merge(_G[self.global], self)
				for k, v in pairs(getmetatable(self)) do
					if type(v) == "function" then
						_G[self.global][k] = v
					end
				end
			end
		else
			rawset(_G, self.global, self)
		end
	end
    for _, module in pairs(self._modules) do
        if (not ignored_modules or not table.contains(ignored_modules, module._name)) then
            local success, err = pcall(function() module:post_init() end)
            if not success then
                self:LogF(LogLevel.ERROR, "BLTModSetup", "An error occured on the post initialization of %s. Error:\n%s", module._name, tostring(err))
            end
        end
    end
end

function BLTModExtended:Setup()
	BLT:_Log(LogLevel.INFO, "BLTModSetup", "Setting up mod:", self:GetId())
	self:SetupCheck()
	if not self._early_init then
        self:InitModules()
    end
end

function BLTModExtended:GetVersion(...)
    local version = BLTModExtended.super.GetVersion(self, ...)
    if not version and self.auto_updates and self.auto_updates.version then
        return self.auto_updates.version
    end
    return version
end

function BLTModExtended:AddHooks(data_key, destination, wildcards_destination)
end