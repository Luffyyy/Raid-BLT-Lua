OptionModule = OptionModule or class(ModuleBase)

--TODO: make build_menu functional.
OptionModule.type_name = "options"

function OptionModule:init(core_mod, config)
    self.required_params = table.add(clone(self.required_params), {"options"})
    self._name = config.name or "Options"

    if not OptionModule.super.init(self, core_mod, config) then
        return false
    end

    self.SavePath = self._config.save_path or SavePath
    self.FileName = self._config.save_file or self._mod.name .. "Options.txt"

    self._storage = {}
    self._menus = {}
    if self._config.loaded_callback then
        self._on_load_callback = self._mod:StringToCallback(self._config.loaded_callback)
    end

    if self._config.build_menu ~= nil then
        self._config.auto_build_menu = self._config.build_menu
    end
    
    if self._config.auto_build_menu == nil or self._config.auto_build_menu then
        self:BuildMenuHook()
    end

    return true
end

function OptionModule:post_init()
    if self._post_init_complete then
        return false
    end

    self:InitOptions(self._config.options, self._storage)

    if self._config.value_changed then
        self._value_changed = self._mod:StringToCallback(self._config.value_changed)
    end

    if self._config.auto_load == nil or self._config.auto_load then
        self:Load()
    end

    OptionModule.super.post_init(self)

    return true
end

function OptionModule:Load()
    if not FileIO:Exists(self.SavePath .. self.FileName) then
        --Save the Options file with the current option values
        self:Save()
        return
    end

    local file = io.open(self.SavePath .. self.FileName, 'r')

    --pcall for json decoding
    local data = json.decode_or_nil(file:read("*all"))

    if not data then
        BLT:log("[ERROR] Unable to load save file for mod, " .. self._mod.name)
        BLT:log(tostring(data))

        --Save the corrupted file incase the option values should be recovered
        local corrupted_file = io.open(self.SavePath .. self.FileName .. "_corrupted", "w+")
        corrupted_file:write(file:read("*all"))

        corrupted_file:close()

        --Save the Options file with the current option values
        self:Save()
        return
    end

    --Close the file handle
    file:close()

    --Merge the loaded options with the existing options
    self:ApplyValues(self._storage, data)

    if self._on_load_callback then
        self._on_load_callback()
    end
end

function OptionModule:ApplyValues(tbl, value_tbl)
    if tbl._meta == "option_set" and tbl.not_pre_generated then
        for key, value in pairs(value_tbl) do
            local new_tbl = Utils:RemoveAllNumberIndexes(tbl.item_parameters and deep_clone(tbl.item_parameters) or {})
            new_tbl._meta = "option"
            new_tbl.name = key
            new_tbl.value = value
            tbl[key] = new_tbl
        end
        return
    end

    for i, sub_tbl in pairs(tbl) do
        if type(sub_tbl) == "table" and sub_tbl._meta then
            if sub_tbl._meta == "option" and value_tbl[sub_tbl.name] ~= nil then
                local value = value_tbl[sub_tbl.name]
                if sub_tbl.type == "multichoice" then
                    if sub_tbl.save_value then
                        local index = table.index_of(sub_tbl.values, value)
                        value = index ~= -1 and index or sub_tbl.default_value
                    else
                        if value > #sub_tbl.values then
                            value = sub_tbl.default_value
                        end
                    end
                end
                sub_tbl.value = value
            elseif (sub_tbl._meta == "option_group" or sub_tbl._meta == "option_set") and value_tbl[sub_tbl.name] then
                self:ApplyValues(sub_tbl, value_tbl[sub_tbl.name])
            end
        end
    end
end

function OptionModule:InitOptions(tbl, option_tbl)
    for i, sub_tbl in ipairs(tbl) do
        if sub_tbl._meta then
            if sub_tbl._meta == "option" then
                if sub_tbl.type == "multichoice" then
                    sub_tbl.values = sub_tbl.values_tbl and self._mod:StringToTable(sub_tbl.values_tbl) or Utils:RemoveNonNumberIndexes(sub_tbl.values)
                end

                if sub_tbl.value_changed then
                    sub_tbl.value_changed = self._mod:StringToCallback(sub_tbl.value_changed)
                end

                if sub_tbl.converter then
                    sub_tbl.converter = self._mod:StringToCallback(sub_tbl.converter)
                end

                if sub_tbl.enabled_callback then
                    sub_tbl.enabled_callback = self._mod:StringToCallback(sub_tbl.enabled_callback)
                end
                sub_tbl.default_value = type(sub_tbl.default_value) == "string" and Utils:normalize_string_value(sub_tbl.default_value) or sub_tbl.default_value
                option_tbl[sub_tbl.name] = sub_tbl
                option_tbl[sub_tbl.name].value = sub_tbl.default_value
            elseif sub_tbl._meta == "option_group" then
                option_tbl[sub_tbl.name] = Utils:RemoveAllSubTables(clone(sub_tbl))
                self:InitOptions(sub_tbl, option_tbl[sub_tbl.name])
            elseif sub_tbl._meta == "option_set" then
                if not sub_tbl.not_pre_generated then
                    local tbl = sub_tbl.items and Utils:RemoveNonNumberIndexes(sub_tbl.items)
                    if sub_tbl.items_tbl then
                        tbl = self._mod:StringToTable(sub_tbl.values_tbl)
                    elseif sub_tbl.populate_items then
                        local clbk = self._mod:StringToCallback(sub_tbl.populate_items)
                        tbl = assert(clbk)()
                    end

                    for _, item in pairs(tbl) do
                        local new_tbl = Utils:RemoveAllNumberIndexes(deep_clone(sub_tbl.item_parameters))
                        new_tbl._meta = "option"
                        table.insert(sub_tbl, table.merge(new_tbl, item))
                    end
                end
                option_tbl[sub_tbl.name] = Utils:RemoveAllSubTables(clone(sub_tbl))
                self:InitOptions(sub_tbl, option_tbl[sub_tbl.name])
            end
        end
    end
end

--Only for use by the SetValue function
function OptionModule:_SetValue(tbl, name, value, full_name)
    if tbl.type == "table" then
        tbl.value[name] = value
        if tbl.value_changed then
            tbl.value_changed(full_name, value)
        end
        if self._value_changed then
            self._value_changed(full_name, value)
        end
    else
        if tbl[name] == nil then
            BLT:log(string.format("[ERROR] Option of name %q does not exist in mod, %s", name, self._mod.name))
            return
        end
        tbl[name].value = value

        if tbl[name].value_changed then
            tbl[name].value_changed(full_name, value)
        end
        if self._value_changed then
            self._value_changed(full_name, value)
        end
    end
end

function OptionModule:SetValue(name, value)
    if string.find(name, "/") then
        local string_split = string.split(name, "/")

        local option_name = table.remove(string_split)

        local tbl = self._storage
        for _, part in pairs(string_split) do
            if tbl[part] == nil then
                BLT:log(string.format("[ERROR] Option Group of name %q does not exist in mod, %s", name, self._mod.name))
                return
            end
            tbl = tbl[part]
        end

        self:_SetValue(tbl, option_name, value, name)
    else
        self:_SetValue(self._storage, name, value, name)
    end

    self:Save()
end

function OptionModule:GetOption(name)
    if string.find(name, "/") then
        local string_split = string.split(name, "/")

        local option_name = table.remove(string_split)

        local tbl = self._storage
        for _, part in pairs(string_split) do
            if tbl[part] == nil then
                if tbl.type ~= "table" then
                    BLT:log(string.format("[ERROR] Option of name %q does not exist in mod, %s", name, self._mod.name))
                end
                return
            end
            tbl = tbl[part]
        end

        return tbl[option_name]
    else
        return self._storage[name]
    end
end

function OptionModule:GetValue(name, real)
    local option = self:GetOption(name)
    if option then
        if real == true then
            if option.converter then
                return option.converter(option, option.value)
            elseif option.type == "multichoice" then
                if type(option.values[option.value]) == "table" then
                    return option.values[option.value].value
                else
                    return option.values[option.value]
                end
            end
        end
        return (type(option) ~= "table" and option) or option.value
    else
        return nil
    end

    return option.value or nil
end

function OptionModule:LoadDefaultValues()
    self:_LoadDefaultValues(self._storage)
end

function OptionModule:_LoadDefaultValues(option_tbl)
    for i, sub_tbl in pairs(option_tbl) do
        if sub_tbl._meta then
            if sub_tbl._meta == "option" and sub_tbl.default_value ~= nil then
                option_tbl[sub_tbl.name].value = sub_tbl.default_value
            elseif sub_tbl._meta == "option_group" or sub_tbl._meta == "option_set" then
                self:_LoadDefaultValues(option_tbl[sub_tbl.name])
            end
        end
    end
end

function OptionModule:PopulateSaveTable(tbl, save_tbl)
    for i, sub_tbl in pairs(tbl) do
        if type(sub_tbl) == "table" and sub_tbl._meta then
            if sub_tbl._meta == "option" then
                local value = sub_tbl.value
                if sub_tbl.type=="multichoice" and sub_tbl.save_value then
                    if type(sub_tbl.values[sub_tbl.value]) == "table" then
                        value = sub_tbl.values[sub_tbl.value].value
                    else
                        value = sub_tbl.values[sub_tbl.value]
                    end
                end
                save_tbl[sub_tbl.name] = value
            elseif sub_tbl._meta == "option_group" or sub_tbl._meta == "option_set" then
                save_tbl[sub_tbl.name] = {}
                self:PopulateSaveTable(sub_tbl, save_tbl[sub_tbl.name])
            end
        end
    end
end

function OptionModule:Save()
    local file = io.open(self.SavePath .. self.FileName, "w+")
    local save_data = {}
    self:PopulateSaveTable(self._storage, save_data)
	file:write(json.encode(save_data))
	file:close()
end

function OptionModule:GetParameter(tbl, i)
    if tbl[i] then
        if type(tbl[i]) == "function" then
            return tbl[i]()
        else
            return tbl[i]
        end
    end

    return nil
end

function OptionModule:CreateSlider(menu, option_tbl, option_path)
    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name
    local enabled = not self:GetParameter(option_tbl, "disabled")
    if option_tbl.enabled_callback then
        enabled = option_tbl:enabled_callback()
    end

    local merge_data = self:GetParameter(option_tbl, "merge_data") or {}
    merge_data = Utils:RemoveAllNumberIndexes(merge_data)
    
    table.insert(menu._items_data, table.merge({
        type = "Slider",
        name = self:GetParameter(option_tbl, "name"),
        text = self:GetParameter(option_tbl, "text") or self._mod.name .. option_tbl.name .. "Text",
        callback = callback(self, self, "ItemValueChanged"),
        min = self:GetParameter(option_tbl, "min"),
        max = self:GetParameter(option_tbl, "max"),
        step = self:GetParameter(option_tbl, "step"),
        enabled = enabled,
        value_name = option_path
    }, merge_data))
end

function OptionModule:CreateToggle(menu, option_tbl, option_path)
    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name
    local enabled = not self:GetParameter(option_tbl, "disabled")
    if option_tbl.enabled_callback then
        enabled = option_tbl:enabled_callback()
    end

    local merge_data = self:GetParameter(option_tbl, "merge_data") or {}
    merge_data = Utils:RemoveAllNumberIndexes(merge_data)

    table.insert(menu._items_data, table.merge({
        type = "Toggle",
        name = self:GetParameter(option_tbl, "name"),
        text = self:GetParameter(option_tbl, "text") or self._mod.name .. option_tbl.name .. "Text",
        callback = callback(self, self, "ItemValueChanged"),
        enabled = enabled,
        value_name = option_path
    }, merge_data))
end

function OptionModule:CreateMultiChoice(menu, option_tbl, option_path)
    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name
    local options = self:GetParameter(option_tbl, "values")
    if not options then
        BLT:log("[ERROR] Unable to get an option table for option " .. option_tbl.name)
        return
    end
    local enabled = not self:GetParameter(option_tbl, "disabled")
    if option_tbl.enabled_callback then
        enabled = option_tbl:enabled_callback()
    end

    local merge_data = self:GetParameter(option_tbl, "merge_data") or {}
    merge_data = Utils:RemoveAllNumberIndexes(merge_data)

    table.insert(menu._items_data, table.merge({
        type = "MultiChoice",
        name = self:GetParameter(option_tbl, "name"),
        text = self:GetParameter(option_tbl, "text") or self._mod.name .. option_tbl.name .. "Text",
        callback = callback(self, self, "MultiChoiceItemValueChanged"),
        value_is_index = true,
        items = options,
        enabled = enabled,
        value_name = option_path
    }, merge_data))
end

function OptionModule:CreateMatrix(menu, option_tbl, option_path, components)
    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name
    local enabled = not self:GetParameter(option_tbl, "disabled")
    if option_tbl.enabled_callback then
        enabled = option_tbl:enabled_callback()
    end

    local scale_factor = self:GetParameter(option_tbl, "scale_factor") or 1
    local merge_data = self:GetParameter(option_tbl, "merge_data") or {}
    merge_data = Utils:RemoveAllNumberIndexes(merge_data)

    local base_params = table.merge({
        type = "Slider",
        name = self:GetParameter(option_tbl, "name"),
        text = managers.localization:text(self:GetParameter(option_tbl, "title_id") or self._mod.name .. option_tbl.name .. "Text"),
        callback = callback(self, self, "MatrixItemValueChanged"),
        min = self:GetParameter(option_tbl, "min") or 0,
        max = self:GetParameter(option_tbl, "max") or scale_factor,
        step = self:GetParameter(option_tbl, "step") or (scale_factor > 1 and 1 or 0.01),
        localize = false,
        enabled = enabled,
        scale_factor = scale_factor,
        get_value = function(value_name, item)
            local val, component = self:GetValue(item.value_name), item.component
            return (type(val[component]) == "function" and val[component](val) or val[component] or 0) * scale_factor
        end,
        value_name = option_path,
        opt_type = option_tbl.type
    }, merge_data)

    for _, vec in pairs(components) do
        local params = clone(base_params)
        params.name = params.name .. "-" .. vec.id
        params.text = params.text .. " - " .. vec.title
        params.component = vec.id
        if vec.max then
            params.max = vec.max
        end
        table.insert(menu._items_data, params)
    end
end

function OptionModule:CreateColour(menu, option_tbl, option_path)
    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name
    local enabled = not self:GetParameter(option_tbl, "disabled")
    if option_tbl.enabled_callback then
        enabled = option_tbl:enabled_callback()
    end

    local merge_data = self:GetParameter(option_tbl, "merge_data") or {}
    merge_data = Utils:RemoveAllNumberIndexes(merge_data)
    
    table.insert(menu._items_data, table.merge({
        type = "ColorButton",
        name = self:GetParameter(option_tbl, "name"),
        text = self:GetParameter(option_tbl, "text") or self._mod.name .. option_tbl.name .. "Text",
        callback = callback(self, self, "ItemValueChanged"),
        enabled = enabled,
        value_name = option_path
    }, merge_data))
end

function OptionModule:CreateVector(menu, option_tbl, option_path)
    self:CreateMatrix(menu, option_tbl, option_path, { {id="x", title="X"}, {id="y", title="Y"}, {id="z", title="Z"} })
end

function OptionModule:CreateRotation(menu, option_tbl, option_path)
    self:CreateMatrix(menu, option_tbl, option_path, { {id="yaw", title="YAW"}, {id="pitch", title="PITCH"}, {id="roll", title="ROLL", max=90} })
end

function OptionModule:CreateOption(menu, option_tbl, option_path)
    if option_tbl.type == "number" then
        self:CreateSlider(menu, option_tbl, option_path)
    elseif option_tbl.type == "bool" or option_tbl.type == "boolean" then
        self:CreateToggle(menu, option_tbl, option_path)
    elseif option_tbl.type == "multichoice" then
        self:CreateMultiChoice(menu, option_tbl, option_path)
    elseif option_tbl.type == "colour" or option_tbl.type == "color" then
        self:CreateColour(menu, option_tbl, option_path)
    elseif option_tbl.type == "vector" then
        self:CreateVector(menu, option_tbl, option_path)
    elseif option_tbl.type == "rotation" then
        self:CreateRotation(menu, option_tbl, option_path)
    else
        BLT:log("[ERROR] No supported type for option " .. tostring(option_tbl.name) .. " in mod " .. self._mod.name)
    end
end

--Add title and subtitle later
function OptionModule:CreateDivider(menu, tbl, type)
    local merge_data = self:GetParameter(tbl, "merge_data") or {}
    merge_data = Utils:RemoveAllNumberIndexes(merge_data)
    table.insert(menu._items_data, table.merge({
        type = type and string.CamelCase(type) or "Label",
        name = self:GetParameter(tbl, "name"),
        text = self:GetParameter(tbl, "text"),
        y_offset = self:GetParameter(tbl, "y_offset"),
        localize = self:GetParameter(tbl, "localize")
    }, merge_data))
end

function OptionModule:CreateSubMenu(menu, option_tbl, option_path)
    option_path = option_path or ""
    local name = self:GetParameter(option_tbl, "name")
    local base_name = name and self._mod.name .. name .. self._name or self._mod.name .. self._name

    local clss = class(BLTMenu)
    clss._items_data = {}
    clss._get_value = callback(self, self, "GetValue")
    clss._mod = self._mod
    self._menus[base_name] = clss
    RaidMenuHelper:CreateMenu({
		name = base_name,
		name_id = self:GetParameter(option_tbl, "title_id") or base_name .. "ButtonText",
        inject_menu = menu,
        class = clss
	})

    if option_tbl.build_items == nil or option_tbl.build_items then
        self:InitializeMenu(clss, option_tbl, name and (option_path == "" and name or option_path .. "/" .. name) or "")
    end
end

function OptionModule:InitializeMenu(menu, option_tbl, option_path)
    option_tbl = option_tbl or self._config.options
    option_path = option_path or ""
    for i, sub_tbl in ipairs(option_tbl) do
        local meta = sub_tbl._meta
        if meta then
            if meta == "option" and not sub_tbl.hidden then
                self:CreateOption(menu, sub_tbl, option_path)
            elseif meta == "divider" or meta == "label" or meta == "title" or meta == "sub_title" then
                self:CreateDivider(menu, sub_tbl, meta ~= "divider" and meta)
            elseif meta == "option_group" or sub_tbl._meta == "option_set" and (sub_tbl.build_menu == nil or sub_tbl.build_menu) then
                self:CreateSubMenu(menu._name, sub_tbl, option_path)
            end
        end
    end
end

function OptionModule:BuildMenuHook()
    Hooks:Add("MenuComponentManagerInitialize", self._mod.name .. "Build" .. self._name .. "Menu", function(self_menu, nodes)	
        self:BuildMenu(BLTModManager.Constants.BLTOptions)
    end)
end

function OptionModule:BuildMenu(menu)
    self:CreateSubMenu(menu, self._config.options)
end

function OptionModule:ItemValueChanged(value, item)
    self:SetValue(item._params.value_name, value)
    self:Save()
end

function OptionModule:MultiChoiceItemValueChanged(selected, item)
    self:SetValue(item._params.value_name, table.get_key(item._params.data_source_callback(), selected))
    self:Save()
end

function OptionModule:MatrixItemValueChanged(value, item)
    local cur_val = self:GetValue(item._params.value_name)
    local comp = item._params.component
    local new_value = value / item._params.scale_factor
    if item._params.opt_type == "vector" then
        if comp == "x" then
            mvector3.set_x(cur_val, new_value)
        elseif comp == "y" then
            mvector3.set_y(cur_val, new_value)
        elseif comp == "z" then
            mvector3.set_z(cur_val, new_value)
        end
    elseif item._params.opt_type == "rotation" then
        mrotation.set_yaw_pitch_roll(cur_val, comp == "yaw" and new_value or cur_val:yaw(), comp == "pitch" and new_value or cur_val:pitch(), comp == "roll" and new_value or cur_val:roll())
    end
    item._params.val = cur_val
    self:SetValue(item._params.value_name, cur_val)
    self:Save()
end

BLT:RegisterModule(OptionModule.type_name, OptionModule)