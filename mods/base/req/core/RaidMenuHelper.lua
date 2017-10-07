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
        self:InjectButtonsIntoList(params.inject_list, params.inject_after, {
            self:PrepareListButton(params.name_id, self:MakeNextMenuClbk(name), params.flags)
        })
    end
    return params.name
end

function RaidMenuHelper:InjectButtonsIntoList(list, point, buttons)
    BLT.Menus[list] = BLT.Menus[list] or {}
    table.insert(BLT.Menus[list], {
        buttons = buttons,
        point = point
    })
end

function RaidMenuHelper:PrepareListButton(text, callback_s, flags)
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