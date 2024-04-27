ModuleBase = ModuleBase or class()
ModuleBase.type_name = "ModuleBase"
ModuleBase.required_params = {}
function ModuleBase:init(core_mod, config)
    self._mod = core_mod
    self._name = self._name or config.name or config._meta or self.type_name
    self._config = config

    if config.file ~= nil then
        local file = io.open(self._mod:GetRealFilePath(Path:Combine(self._mod.path, config.file)), "r")
        if file then
            self._config = table.merge(config, ScriptSerializer:from_custom_xml(file:read("*all")))
        end
    end

    for _, param in pairs(self.required_params) do
        if Utils:StringToTable(param, self._config, true) == nil then
            self:LogF(LogLevel.ERROR, "Parameter '%s' is required!", param)
            return false
        end
    end

    return true
end

function ModuleBase:post_init()
    if self._post_init_complete then
        return false
    end

    if self._config.post_init_clbk then
        local clbk = self._mod:StringToCallback(self._config.post_init_clbk)
        if clbk then
            clbk()
        end
    end

    self._post_init_complete = true
    return true
end

function ModuleBase:Log(lvl, cat, ...)
    cat = "<" .. cat .. ">"
    return self._mod:Log(lvl, cat, ...)
end

function ModuleBase:LogF(lvl, cat, ...)
    cat = "<" .. cat .. ">"
    return self._mod:LogF(lvl, cat, ...)
end

function ModuleBase:LogC(lvl, cat, ...)
    cat = "<" .. cat .. ">"
    return self._mod:LogC(lvl, cat, ...)
end

function ModuleBase:log(...)
    return self._mod:log(...)
end

ItemModuleBase = ItemModuleBase or class(ModuleBase)
ItemModuleBase.type_name = "ItemModuleBase"
ItemModuleBase.required_params = { "id" }
ItemModuleBase.clean_table = {}
ItemModuleBase.defaults = { global_value = "mod", dlc = "mod" }
ItemModuleBase._loose = true
local remove_last = function(str)
    local tbl = string.split(str, "%.")

    return table.remove(tbl), #tbl > 0 and table.concat(tbl, ".")
end

function ItemModuleBase:init(core_mod, config)
    if not ModuleBase.init(self, core_mod, config) then
        return false
    end
    self:do_clean_table(self._config)
    return true
end

function ItemModuleBase:do_clean_table(config)
    for _, clean in pairs(self.clean_table) do
        local i, search_string = remove_last(clean.param)
        local tbl = search_string and Utils:StringToTable(search_string, config, true) or config
        if tbl and tbl[i] then
            for _, action in pairs(type(clean.action) == "table" and clean.action or { clean.action }) do
                if action == "no_subtables" then
                    tbl[i] = Utils:RemoveAllSubTables(tbl[i])
                elseif action == "no_number_indexes" then
                    tbl[i] = Utils:RemoveAllNumberIndexes(tbl[i], clean.shallow)
                elseif action == "number_indexes" then
                    tbl[i] = Utils:RemoveNonNumberIndexes(tbl[i])
                elseif action == "remove_metas" then
                    tbl[i] = Utils:RemoveMetas(tbl[i], clean.shallow)
                elseif action == "normalize" then
                    tbl[i] = Utils:normalize_string_value(tbl[i])
                elseif action == "children_no_number_indexes" then
                    for _, v in pairs(tbl[i]) do
                        v = Utils:RemoveAllNumberIndexes(v, clean.shallow)
                    end
                elseif type(action) == "function" then
                    action(tbl[i])
                end
            end
        end
    end
end

function ItemModuleBase:RegisterHook() end
