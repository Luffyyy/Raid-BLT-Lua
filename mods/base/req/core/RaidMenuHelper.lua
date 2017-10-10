--This time it's used more by BLT than the user, this class might have more usage by the user in the future.
--I just like the idea of having a class that has item creation functions
RaidMenuHelper = RaidMenuHelper or {}
function RaidMenuHelper:CreateMenu(params)
    local name = params.name
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
					back_callback = params.back_callback,
					topic_id = params.topic_id or name,
					menu_components = params.menu_components or ("raid_menu_header raid_menu_footer raid_back_button " .. (params.components or name)),
					node_background_width = params.background_width or 0.4,
					node_padding = params.padding or 30
				}
			}
		}
	})
	if managers.raid_menu then
		managers.raid_menu.menus[name] = {name = name}
	end
	if params.class then
        if managers.menu_component then
            self:CreateComponent(params.created_component or name, params.class)
        else
            log("[ERROR] You're building the menu too early! menu component isn't loaded yet.")
        end
    end
    if params.inject_list then
        self:InjectButtons(params.inject_list, params.inject_after, {
            self:PrepareListButton(params.name_id, params.localize, self:MakeNextMenuClbk(name), params.flags)
		}, true)
	elseif params.inject_menu then
        self:InjectButtons(params.inject_menu, params.inject_after, {
            self:PrepareButton(params.name_id,  params.localize, function() managers.raid_menu:open_menu(name) end)
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
	else
		log("[BLT][ERROR] Failed reading json file at path %s", tostring(path))
	end
end

function RaidMenuHelper:LoadXML(path)
	local file = io.open(path, "r")
	if file then
		local data = ScriptSerializer:from_custom_xml(file:read("*all"))
		if data and data.items then
			for _, v in pairs(data.items) do --conver _meta to type
				if type(v) == "table" then
					if v._meta then
						v.type = v._meta
						v._meta = nil
					end
				end
			end
			self:LoadMenu(data)
		end
	else
		log("[BLT][ERROR] Failed reading XML file at path %s", tostring(path))
	end
end

function RaidMenuHelper:LoadMenu(data)
	if not data.menu then
		log("[BLT][ERROR] Creation of menu at path %s has failed, no menu data given.")
	end
	local clss
	local get_value
	file:close()
	Hooks:Add("MenuComponentManagerInitialize", tostring(data.name)..".MenuComponentManagerInitialize", function(self)
		local menu = data.menu
		if menu.class then
			menu.class = loadstring("return "..tostring(menu.class))
			clss = menu.class
		end
		if menu.get_value then
			if menu.get_value:starts("callback") then
				get_value = loadstring("return "..tostring(menu.get_value))
			elseif self[menu.callback] then
				get_value = callback(self, self, menu.get_value)
			else
				log(string.format("[BLT][Warning] Get value function given in menu named %s doesn't exist."), tostring(data.menu.name))
			end
			menu.get_value = nil
		end
		RaidMenuHelper:CreateMenu({
			name = data.name,
			name_id = data.name_id,
			localize = data.localize,
			class = clss,
			inject_menu = data.inject_menu,
		})
	end)
	if clss then
		function clss:InitMenuData(root)
			for k, item in pairs(data.items) do
				--make background options?
				if item.callback then
					if item.callback:starts("callback") then
						item.callback = loadstring("return "..tostring(item.callback))
					elseif self[item.callback] then
						item.callback = callback(self, self, item.callback)
					else
						log(string.format("[BLT][Warning] Callback given to item named %s in menu named %s doesn't exist"), tostring(item.name), tostring(data.menu.name))
					end
				end
				if item.value then
					if get_value then
						item.value = get_value(item.value)
					else
						log("[BLT][Warning] Get value function was not given, cannot set values without it.")
					end
				end
				local type = item.type
				if self[type] then
					item.type = nil
					self[type](self, item)
				end
			end					
		end
	else
		log(string.format("[BLT][ERROR] Failed to create menu named %s, no class given!"), tostring(data.menu.name))
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