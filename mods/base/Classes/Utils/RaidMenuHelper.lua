--This time it's used more by BLT than the user, this class might have more usage by the user in the future.
--I just like the idea of having a class that has item creation functions
RaidMenuHelper = RaidMenuHelper or {}
function RaidMenuHelper:CreateMenu(params)
	local name = string.gsub(params.name, "%s", "") --remove spaces from names, it doesn't seem to like them that much.
	local component_name = params.component_name or name
	managers.menu:register_menu_new({
		name = name,
		input = params.input or "MenuInput",
		renderer = params.renderer or "MenuRenderer",
		callback_handler = params.callback_handler or MenuCallbackHandler,
		config = {
			{
				_meta = "menu",
				id = params.id or name,
				{_meta = "default_node", name = name},
				{
					_meta = "node",
					gui_class = params.gui_class or "MenuNodeGuiRaid",
					name = params.node_name or name,
					topic_id = params.topic_id or name,
					menu_components = params.menu_components or ("raid_menu_header raid_menu_footer raid_back_button " .. (params.components or name or "")),
					node_background_width = params.background_width or 0.4,
					node_padding = params.padding or 30
				}
			}
		}
	})
	if managers.raid_menu then
		managers.raid_menu.menus[component_name] = {name = component_name}
	end
	if params.class then
        if managers.menu_component then
            self:CreateComponent(component_name, params.class)
        else
            log("[ERROR] You're building the menu too early! menu component isn't loaded yet.")
        end
    end
    if params.inject_list then
        self:InjectButtons(params.inject_list, params.inject_after, {
            self:PrepareListButton(params.name_id or params.text, params.localize, self:MakeNextMenuClbk(component_name), params.flags)
		}, true)
	elseif params.inject_menu then
        self:InjectButtons(params.inject_menu, params.inject_after, {
            self:PrepareButton(params.name_id or params.text, params.localize, function() log("OPEN MENU", tostring(component_name)) managers.raid_menu:open_menu(component_name) end)
		})		
    end
    return params.name
end

function RaidMenuHelper:InjectButtons(menu, point, buttons, is_list)
    BLT.Menus[menu] = BLT.Menus[menu] or {}
    table.insert(BLT.Menus[menu], {
        buttons = buttons,
		point = point,
		is_list = is_list
    })
end

function RaidMenuHelper:PrepareButton(text, localize, callback)
	return {
		text = text,
		localize = localize,
		callback = callback,
	}
end

function RaidMenuHelper:PrepareListButton(text, localize, callback_s, flags)
	return {
		text = managers.localization:to_upper_text(text),
		callback = callback_s,
		availability_flags = flags
	}
end

function RaidMenuHelper:MakeClbk(name, func)
	RaidMenuCallbackHandler[name] = RaidMenuCallbackHandler[name] or func
	return name
end

function RaidMenuHelper:MakeNextMenuClbk(next_menu)
	local id = "open_menu_" .. next_menu
	RaidMenuCallbackHandler[id] = RaidMenuCallbackHandler[id] or function(this)
        managers.raid_menu:open_menu(next_menu)
	end
	return id
end

function RaidMenuHelper:InjectIntoAList(menu_comp, injection_point, buttons, list_name)
	local list = (list_name and menu_comp[list_name]) or menu_comp._list_menu or menu_comp.list_menu_options
	if list then
		if not list._injected_data_source then
			list._orig_data_source_callback = list._orig_data_source_callback or list._data_source_callback
			list._injected_to_data_source = list._injected_to_data_source or {}			
			list._data_source_callback = function()
				local t = list._orig_data_source_callback()
				for _, inject in pairs(list._injected_to_data_source) do
					if inject.buttons then
						for i, item in pairs(t) do
							if (not inject.point and i == #t) or tostring(item.text):lower() == tostring(inject.point):lower() then
								for k = #inject.buttons, 1, -1 do
									table.insert(t, i + 1, inject.buttons[k])
								end
								break
							end
						end
					end
				end
				return t
			end
		end
		table.insert(list._injected_to_data_source, {buttons = buttons, point = injection_point})
		list:refresh_data()
	else
		log("[ERROR] Menu component given has no list, cannot inject into this menu.")
	end
end

function RaidMenuHelper:CreateComponent(name, clss)
	local comp = managers.menu_component
	clss._name = name
    comp._active_components[name] = {
        create = function(node)
			if node then
				comp[name] = comp[name] or clss:new(comp._ws, comp._fullscreen_ws, node)
            end
            return comp[name]	
        end, 
        close = function()
            if comp[name] then
                comp[name]:close()
                comp[name] = nil
            end
        end
    }
    
    if clss.update then
        Hooks:Add("MenuComponentManagerUpdate", name..".MenuComponentManagerUpdate", function(self, t, dt)
            if comp[name] then
                comp[name]:update(t, dt)
            end
        end)
    end
end

function RaidMenuHelper:LoadJson(path)
	local file = io.open(path, "r")
	if file then
		local data = json.decode(file:read("*all"))
		if data then
			self:LoadMenu(data)
		end
		file:close()
	else
		log(string.format("[BLT][ERROR] Failed reading json file at path %s", tostring(path)))
	end
end

function RaidMenuHelper:LoadXML(path)
	local file = io.open(path, "r")
	if file then
		local data = ScriptSerializer:from_custom_xml(file:read("*all"))
		if data and data.items then
			for _, v in pairs(data.items) do --convert _meta to type
				if type(v) == "table" then
					if v._meta then
						v.type = v._meta
						v._meta = nil
					end
				end
			end
			self:LoadMenu(data)
		end
		file:close()
	else
		log(string.format("[BLT][ERROR] Failed reading XML file at path %s", tostring(path)))
	end
end

function RaidMenuHelper:LoadMenu(data)
	if not data.name then
		log("[BLT][ERROR] Creation of menu at path %s has failed, no menu name given.")
		return
	end
	local clss
	local get_value
	local function load_menu()
		if data.class then
			data.class = loadstring("return "..tostring(data.class))()
			clss = data.class
		else
			clss = class(BLTMenu)
			rawset(_G, clss, data.name.."Menu")
		end
		if data.get_value and clss then
			if data.get_value:starts("callback") then
				get_value = loadstring("return "..tostring(data.get_value))()
			elseif clss[data.callback] then
				get_value = callback(clss, clss, data.get_value)
			elseif type(data.get_value) == "function" then
				get_value = data.get_value
			else
				log(string.format("[BLT][Warning] Get value function given in menu named %s doesn't exist.", tostring(data.name)))
			end
			data.get_value = nil
		end
		RaidMenuHelper:CreateMenu({
			name = data.name,
			name_id = data.name_id,
			localize = data.localize,
			class = clss,
			inject_menu = data.inject_menu,
		})
		if clss then
			local ready_items = {}
			for k, item in ipairs(data.items) do
				if item.callback then
					if item.callback:begins("callback") then
						item.callback = loadstring("return "..tostring(item.callback))
					elseif clss[item.callback] then
						item.callback = callback(clss, clss, item.callback)
					else
						log(string.format("[BLT][Warning] Callback given to item named %s in menu named %s doesn't exist", tostring(item.name), tostring(data.name)))
					end
				end
				table.insert(ready_items, item)
			end
			clss._get_value = get_value
			clss._items_data = ready_items
		else
			log(string.format("[BLT][ERROR] Failed to create menu named %s, invalid class given!", tostring(data.menu.name)))
		end
	end
	if managers.menu_component then
		load_menu()
	else
		Hooks:Add("MenuComponentManagerInitialize", tostring(data.name)..".MenuComponentManagerInitialize", load_menu)		
	end
end

function RaidMenuHelper:ForEachValue(items, value_func)
	if value_func then
		for _, item in pairs(items) do
			if BLTMenu:IsItem(item) and item:visible() then
				value_func(item)
			end
		end
	end
end

function RaidMenuHelper:ResetValues(items)
	self:ForEachValue(items, function(item)
		if item._params.default_value then
			item:set_value(item._params.default_value)
		end
	end)
end