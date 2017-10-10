BLTMenu = BLTMenu or blt_class(RaidGuiBase)
--In Raid menus would be made either with json or by inherting BLTMenu class and adding it to menu components by RaidMenuHelper:CreateMenu
--core functions
function BLTMenu:init(ws, fullscreen_ws, node, name)
    self._ws = ws
    self._fullscreen_ws = fullscreen_ws
    self._fullscreen_panel = self._fullscreen_ws:panel():panel({})
    self._panel = self._ws:panel():panel({})
    --do we need a name..? hard without a decomp :/
    BLTMenu.super.init(self, ws, fullscreen_ws, node, name or "")
    if self.InitMenuData then
        self:InitMenuData(self._root_panel)
    end
    if self.Init then
        self:Init(self._root_panel)
    end
    self:Align(self._root_panel)
end

function BLTMenu:close()
    self._ws:panel():remove(self._panel)
    self._fullscreen_ws:panel():remove(self._fullscreen_panel)
    self._root_panel:clear()
    self:Close()
end

function BLTMenu:_layout(root)
    self:Align(root)
end

function BLTMenu:Align(root)
    root = root or self._root_panel
    local prev_item
    local last_before_reset
    for _, item in pairs(root:get_controls()) do
        if self:IsItem(item) and item:visible() then
            if item and prev_item and (prev_item:bottom() + item:h() + 64) > root:h() then
                if self:AlignItemResetY(item, prev_item) then
                    last_before_reset = prev_item
                    prev_item = nil -- reset y pos
                end
			end
            if prev_item then
                self:AlignItem(item, prev_item, last_before_reset)
            else
                self:AlignItemFirst(item)
				item:set_y(0)
			end
            prev_item = item
		end
	end
end

function BLTMenu:IsItem(item)
    return item._type == "raid_gui_panel" or item._params.align_item
end

function BLTMenu:AlignItemFirst(item)
    item:set_y(0)
end

function BLTMenu:AlignItemResetY(item, prev_item)
    item:set_x(prev_item:right() + (item._params.x_offset or self.default_x_offset))
    return true
end

function BLTMenu:AlignItem(item, prev_item, last_before_reset)
    item:set_x((last_before_reset and last_before_reset:right() or 0) + (item._params.x_offset or self.default_x_offset))
    item:set_y(prev_item:bottom() + (item._params.y_offset or self.default_y_offset))
end

function BLTMenu:Close()
end

--Parameters that all items have
function BLTMenu:BasicItemData(params)
    if params.localize == nil then
        params.localize = true
    end
    if params.text then
        params.text = (params.localize and managers.localization:to_upper_text(params.text) or string.upper(params.text))
    else
        params.text = ""
    end

    params.ignore_align = not not params.ignore_align
    params.value = value
    params.x = params.x
    params.y = params.y
    params.w = params.w or 512
    params.h = params.h or 32
    params.x_offset = params.x_offset or self.default_x_offset or 6
    params.y_offset = params.y_offset or self.default_y_offset or 6
    
    --params.color,
    --params.alpha,
    --params.visible,
    --params.background_color,
    return params
end

function BLTMenu:ReinsertItem(item)
    local params = item._params
    local ctrls = self._root_panel:get_controls()
    local should_reinsert = params.index ~= nil or params._type ~= "raid_gui_panel" 
    if should_reinsert then
        table.delete(ctrls, item)
    end
    if params.index then
        table.insert(ctrls, params.index, item)
    elseif should_reinsert then
        table.insert(ctrls, item)
    end
end

function BLTMenu:CreateSimple(typ, params, textisdesc)
    local parent = params.parent or self._root_panel
    local data = BLTMenu:BasicItemData(params)
    if parent then
        local button = parent[typ](parent, table.merge({
            on_click_callback = params.callback and function(a, item, value)
                params.callback(value, item)
            end,
            text = not textisdesc and params.text or nil,
            description = textisdesc and params.text or nil,
        }, data))
		if params.enabled ~= nil and button.set_enabled then
			button:set_enabled(params.enabled)
        end
        BLTMenu:ReinsertItem(button)
        return button
    end
end

function BLTMenu:Button(params)
    return BLTMenu.CreateSimple(self, "button", params)
end

function BLTMenu:LongRoundedButton2(params)
    return BLTMenu.CreateSimple(self, "long_secondary_button", params)
end

function BLTMenu:RoundedButton2(params)
    return BLTMenu.CreateSimple(self, "short_secondary_button", params)
end

function BLTMenu:RoundedButton(params)
    return BLTMenu.CreateSimple(self, "small_button", params)
end

function BLTMenu:LongRoundedButton(params)
    return BLTMenu.CreateSimple(self, "long_tertiary_button", params)
end

function BLTMenu:CreateSimpleLabel(typ, params)
    params.callback = nil
    params.x_offset = params.x_offset or self.default_label_x_offset or 1
    params.y_offset = params.y_offset or self.default_label_y_offset or 1
    local label = BLTMenu.CreateSimple(self, typ, params)
    label._params.align_item = true
    BLTMenu:ReinsertItem(label)
    return label
end

function BLTMenu:Label(params)
    return BLTMenu.CreateSimpleLabel(self, "label", params)
end

function BLTMenu:Title(params)
    return BLTMenu.CreateSimpleLabel(self, "label_title", params)
end

function BLTMenu:SubTitle(params)
    return BLTMenu.CreateSimpleLabel(self, "label_subtitle", params)    
end

function BLTMenu:Toggle(params)
    return BLTMenu.CreateSimple(self, "toggle_button", params, true)
end

function BLTMenu:Switch(params)
    return BLTMenu.CreateSimple(self, "switch_button", params, true)
end

function BLTMenu:MultiChoice(params)
    local parent = params.parent or self._root_panel
    local data = BLTMenu:BasicItemData(params)
    if parent then
        local multichoice
        multichoice = parent:stepper(table.merge({
            on_menu_move = {},
            data_source_callback = params.items_func or function() return params.items or {} end,
            on_item_selected_callback = function(value)
                params.callback(value, multichoice)
            end,
            description = params.text,
        }, data))
		if params.enabled ~= nil then
			multichoice:set_enabled(params.enabled)
		end
		if params.value ~= nil then
			multichoice:select_item_by_value(params.value)
        end
        BLTMenu:ReinsertItem(multichoice)
        return multichoice
    end
end

function BLTMenu:Slider(params)
    local parent = params.parent or self._root_panel
    local data = BLTMenu:BasicItemData(params)
    if parent then
        local slider
        local max = params.max or 100
        local min = params.min or 0
        slider = parent:slider(table.merge({
            max_display_value = max,
            min_display_value = min,
            value = params.value and ((params.value - min) / (max - min)) * 100, --weirdly doesn't return the correct value in some cases
            on_value_change_callback = params.callback and function(value)
                if value then
                    params.callback(tonumber(slider._value_label:text()), slider)
                end
            end,
            description = params.text and (params.localize and managers.localization:to_upper_text(params.text) or string.upper(params.text)),
        }, data))
        if params.enabled ~= nil then
			slider:set_enabled(params.enabled)
        end
        BLTMenu:ReinsertItem(slider)
        return slider
    end
end

function BLTMenu:Tabs(params)
    local parent = params.parent or self._root_panel
    local data = BLTMenu:BasicItemData(params)
	if parent then
		local tabs
        tabs = parent:tabs(table.merge({
			on_click_callback = function(tab_selected)
				if params.callback then
					params.callback(tab_selected, tabs)
				end
			end,
			dont_trigger_special_buttons = true, --no idea what this does
			tabs_params = params.tabs or {{text = "NO TABS"}},
			initial_tab_idx = params.selected_tab,
			tab_width = params.tab_width or 160,
			tab_height = params.tab_height,			
        }, data))
        if params.enabled ~= nil then
			tabs:set_enabled(params.enabled)
        end
        BLTMenu:ReinsertItem(tabs)
        return tabs
    end
end

--Basically all the shit that was in mods_menu, view_mod and download_manager but instead of fucking repeating it.
BLTCustomMenu = BLTCustomMenu or blt_class(RaidGuiBase)
function BLTCustomMenu:init(ws, fullscreen_ws, node, name)
    self._ws = ws
    self._fullscreen_ws = fullscreen_ws
    self._fullscreen_panel = self._fullscreen_ws:panel():panel({})
    self._panel = self._ws:panel():panel({layer = 20})
    self._init_layer = self._ws:panel():layer()
    
    self._data = node:parameters().menu_component_data or {}
    self._buttons = {}
    self:_setup()
    BLTCustomMenu.super.init(self, ws, fullscreen_ws, node, name)
end

function BLTCustomMenu:close()
    self._ws:panel():remove(self._panel)
    self._fullscreen_ws:panel():remove(self._fullscreen_panel)
    self._root_panel:clear()
end

function BLTCustomMenu:mouse_pressed( o, button, x, y )
	BLTCustomMenu.super.mouse_pressed(self, o, button, x, y)
	local result = false 
	
	for _, item in ipairs( self._buttons ) do 
	   if item:inside( x, y ) then 
		 if item.mouse_clicked then 
		   result = item:mouse_clicked( button, x, y ) 
		 end 
		 break 
	   end 
	end 
	
	if button == Idstring( "0" ) then 
	
		for _, item in ipairs( self._buttons ) do
			if item:inside( x, y ) then
				if item:parameters().callback then
					item:parameters().callback()
				end
				managers.menu_component:post_event( "menu_enter" )
				return true
			end
		end

    end
    
    if alive(self._scroll) then
        return self._scroll:mouse_pressed( o, button, x, y )
    end

	return result
	
end

function BLTCustomMenu:mouse_moved(o, x, y)
    if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
        return false
    end
    BLTCustomMenu.super.mouse_moved(self, o, x, y)

    local used, pointer

    local inside_scroll = alive(self._scroll) and self._scroll:panel():inside( x, y )
    for _, item in ipairs( self._buttons ) do
        if not used and item:inside( x, y ) and inside_scroll then
            item:set_highlight( true )
            used, pointer = true, "link"
        else
            item:set_highlight( false )
        end
    end

    if alive(self._scroll) and not used then
        used, pointer = self._scroll:mouse_moved( o, x, y )
    end

    return used, pointer
end
    
function BLTCustomMenu:mouse_clicked(o, button, x, y)
    if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
        return false
    end

    BLTCustomMenu.super.mouse_clicked(self, o, button, x, y)

    if alive(self._scroll) then
        return self._scroll:mouse_clicked( o, button, x, y )
    end
end

function BLTCustomMenu:mouse_released(o, button, x, y)
	if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
		return false
    end
    
    BLTCustomMenu.super.mouse_released(self, o, button, x, y)
	if alive(self._scroll) then
		return self._scroll:mouse_released( button, x, y )
	end
end

function BLTCustomMenu:mouse_wheel_up( x, y )
	if alive(self._scroll) then
		self._scroll:scroll( x, y, 1 )
	end
end

function BLTCustomMenu:mouse_wheel_down( x, y )
	if alive(self._scroll) then
		self._scroll:scroll( x, y, -1 )
	end
end

function BLTCustomMenu:make_fine_text(text)
    if not alive(text) then
        return
    end
	local x,y,w,h = text:text_rect()
	text:set_size(w, h)
	text:set_position(math.round(text:x()), math.round(text:y()))
end


RaidBackButton = RaidBackButton or blt_class(BLTCustomMenu)
function RaidBackButton:init(ws, fullscreen_ws, node)
    RaidGuiBase:set_legend({
        controller = {"menu_legened_back"},
        keyboard = {{key = "footer_back", callback = callback(managers.raid_menu, managers.raid_menu, "close_menu")}},
    })
end

-------------------------------------------------------------------------------
-- Adds a back button to a menu

Hooks:Add("MenuComponentManagerInitialize", "RaidBackButton.MenuComponentManagerInitialize", function(self)
	self._active_components.raid_back_button = {create = callback(self, self, "create_raid_back_button"), close = callback(self, self, "remove_raid_back_button")}
end)

function MenuComponentManager:remove_raid_back_button(node)
    --no need to lol
end

function MenuComponentManager:create_raid_back_button(node)
	if not node then
		return
    end
    RaidGuiBase:set_legend({
        controller = {"menu_legend_back"},
        keyboard = {{key = "footer_back", callback = RaidGuiBase._on_legend_pc_back}},
    })
end