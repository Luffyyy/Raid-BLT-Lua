local ModPath = ModPath

require("lib/managers/menu/raid_menu/controls/raidguicontrol")
require("lib/managers/menu/raid_menu/controls/raidguicontrolbutton")

dofile(ModPath .. "Classes/UI/Controls/BLTGUIControlButton.lua")
dofile(ModPath .. "Classes/UI/Controls/BLTGUIControlMenuButton.lua")

BLTMenu = BLTMenu or class(RaidGuiBase)
--core functions
function BLTMenu:init(ws, fullscreen_ws, node, name, args)
    self._name = name
    self._ws = ws
    self._fullscreen_ws = fullscreen_ws
    self._fullscreen_panel = self._fullscreen_ws:panel():panel({})
    self._panel = self._ws:panel():panel({})
    self._all_ctrls = {}
    --do we need a name..? hard without a decomp :/
    BLTMenu.super.init(self, ws, fullscreen_ws, node, name or "")
    self._root_panel.ctrls = self._root_panel.ctrls or {}
    if self.PreInit then
        self:PreInit(self._root_panel, args)
    end
    if self.Init then
        self:Init(self._root_panel, args)
    end
    if self._items_data then
        for _, item in ipairs(self._items_data) do
            item.value_name = item.value_name or item.name
            if item.value_name then
                local get_value = item.get_value or self._get_value
                if get_value then
                    if item.value_is_index then
                        item.selected = get_value(item.value_name, item)
                    else
                        item.value = get_value(item.value_name, item)
                    end
                end
            end
            local type = item.type
            if self[type] then
                self[type](self, item)
            end
        end
    end
    self._description_label = self:Label({
        name = "bltmenu_description_label",
        text = "",
        ignore_align = true
    })
    self:adjust_description_label()
    self:Align()
    self:Finalize()
end

function BLTMenu:Clear()
    self._root_panel:clear()
    self._root_panel.ctrls = {}
end

function BLTMenu:close()
    self._ws:panel():remove(self._panel)
    self._fullscreen_ws:panel():remove(self._fullscreen_panel)
    self:Clear()
    self:Close()
end

function BLTMenu:Finalize(panel)
    panel = panel or self._root_panel
    for _, item in pairs(panel:get_controls()) do
        if item.ctrls then
            self:Finalize(item)
        elseif item._params.tabs then
            self:SetPage(nil, item)
        end
    end
end

--Hides only items that have the 'page' parameter.
function BLTMenu:SetPage(page, tabs)
    if not page then
        local tab = tabs._params.tabs[tabs._selected_item_idx]
        page = tab and tab.callback_param
    end

    local parent = tabs._params.parent
    if parent and parent.ctrls then
        for _, item in pairs(parent.ctrls) do
            if item._params.page then
                item:set_visible(page == item._params.page)
            end
        end
        self:Align()
    end
end

function BLTMenu:GetItem(name, deep, panel)
    panel = panel or self._root_panel
    for _, item in pairs(panel.ctrls) do
        if item:name() == name then
            return item
        elseif item.ctrls and deep then
            return self:GetItem(name, deep, item)
        end
    end
    return nil
end

function BLTMenu:GetPanel(name, deep, panel)
    panel = panel or self._root_panel
    for _, item in pairs(panel.ctrls) do
        if item.ctrls then
            if item:name() == name then
                return item
            elseif deep then
                return self:GetItem(name, deep, item)
            end
        end
    end
    return nil
end

function BLTMenu:HideBackground()
    managers.raid_menu:hide_background()
end

function BLTMenu:ShowBackground()
    managers.raid_menu:show_background()
end

function BLTMenu:_layout()
    self:Align()
end

function BLTMenu:Align(panel)
    panel = panel or self._root_panel
    local controls = panel and panel.ctrls

    if not controls then
        return
    end

    local x = 0
    local y = 0
    local next_col_x = 0
    for _, item in pairs(controls) do
        if item:visible() and not item._params.ignore_align then
            local x_offset = item._params.x_offset or self.default_x_offset
            local y_offset = item._params.y_offset or self.default_y_offset

            -- if not first item in column and increasing screen size...
            if (y > 0) and (y + y_offset + item:h()) > (panel:h() - (panel.is_root_panel and 32 or 0)) then
                x = next_col_x -- ...shift column and...
                y = 0          -- ...set to top
            end

            -- set coords
            item:set_x(x + x_offset)
            item:set_y(y + y_offset)

            -- prepare next
            if item:right() > next_col_x then
                next_col_x = item:right() + (item._is_slider and 0 or 64)
            end
            y = item:bottom()
        end
    end
end

function BLTMenu:IsItem(item)
    return item._type == "raid_gui_panel" or item._params.align_item
end

function BLTMenu:Close()
end

--Parameters that all items have
function BLTMenu:BasicItemData(params, no_clone, typ)
    params = no_clone and params or clone(params)

    if params.localize == nil then
        params.localize = true
    end
    if params.upper == nil then
        params.upper = true
    end

    params.name = params.name or params.text or "ERROR"
    if params.text == nil and params.localize then
        params.text = (self._mod and self._mod.name or "") .. params.name .. "Text"
    end

    if params.text then
        params.text = (params.localize and managers.localization:to_upper_text(params.text) or params.upper and string.upper(params.text) or params.text)
    else
        params.text = ""
    end

    params.parent = params.parent or self._root_panel
    params.is_blt = true
    params.ignore_align = not not params.ignore_align
    params.w = (params.w or 512) + (typ == "slider" and 64 or 0)
    params.h = params.h or 32
    params.x_offset = params.x_offset or self.default_x_offset or 6
    params.y_offset = params.y_offset or self.default_y_offset or 6
    params.index = params.index or (params.parent.ctrls and #params.parent.ctrls + 1 or nil)
    params.ws = params.ws or self._ws
    return params
end

function BLTMenu:SortItems(panel)
    panel = panel or self._root_panel
    if panel.ctrls then
        table.sort(panel.ctrls, function(a, b)
            return a._params.index < b._params.index
        end)
    end
end

function BLTMenu:CreateSimple(typ, params, create_data)
    create_data = create_data or {}
    local data = BLTMenu.BasicItemData(self, params, create_data.no_clone, typ)
    local parent = data.parent
    if parent then
        if params.desc then
            if params.localize_desc == nil then
                params.localize_desc = true
            end
            data.on_mouse_exit_callback = callback(self, self, "_hide_description")
            data.on_mouse_enter_callback = callback(self, self, "_show_description", params)
        end
        local clbk_key = create_data.clbk_key or "on_click_callback"
        data[clbk_key] = data.callback and (create_data.default_clbk or function(a, item, value)
            data.callback(value, item)
        end)
        local text_key = create_data.text_key or "text"
        data[text_key] = create_data.text_key ~= false and data.text or ""
        local item
        if type(typ) == "table" then
            item = typ:new(parent, data)
            parent:_add_control(item)
        else
            item = parent[typ](parent, data)
        end
        if params.enabled ~= nil and item.set_enabled then
            item:set_enabled(params.enabled)
        end
        if parent.ctrls then
            local insert = item._object and item._object._params and item._object or item
            insert._params.index = data.index
            insert._params.ignore_align = data.ignore_align
            insert._params.x_offset = insert._params.x_offset or data.x_offset
            insert._params.y_offset = insert._params.y_offset or data.y_offset
            table.insert(parent.ctrls, insert)
        end
        table.insert(self._all_ctrls, item)
        self:SortItems(parent)
        self:Align(parent)
        return item
    end
end

function BLTMenu:adjust_description_label()
    local _, _, w, _ = MenuNodeBaseGui.make_fine_text(self._description_label._object)
    self._description_label:set_width(w)
    self._description_label:set_right(managers.viewport:get_safe_rect_pixels().width)
end

function BLTMenu:_show_description(params)
    if params.desc then
        self._description_label:set_text(string.gsub(params.localize_desc and managers.localization:text(params.desc) or params.desc, "\n", " "))
        self:adjust_description_label()
        self._description_label:set_visible(true)
    end
end

function BLTMenu:_hide_description()
    self._description_label:set_visible(false)
end
--Item creation functions

function BLTMenu:Button(params)
    return BLTMenu.CreateSimple(self, BLTGUIControlButton, params)
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

function BLTMenu:MenuButton(params)
    return BLTMenu.CreateSimple(self, BLTGUIControlMenuButton, params)
end

function BLTMenu:CreateSimpleLabel(typ, params)
    params = clone(params)
    params.callback = nil
    params.x_offset = params.x_offset or self.default_label_x_offset or 1
    params.y_offset = params.y_offset or self.default_label_y_offset or 1
    params.text = NotNil(params.text, false)
    local label = BLTMenu.CreateSimple(self, typ, params, { no_clone = true })
    label._params.align_item = true
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
    return BLTMenu.CreateSimple(self, "toggle_button", params, { text_key = "description" })
end

function BLTMenu:Switch(params)
    return BLTMenu.CreateSimple(self, "switch_button", params, { text_key = "description" })
end

function BLTMenu:MultiChoice(params)
    params = clone(params)
    params.data_source_callback = params.items_func or function() return params.items or {} end
    local item
    item = BLTMenu.CreateSimple(self, "stepper", params,
        {
            no_clone = true,
            text_key = "description",
            clbk_key = "on_item_selected_callback",
            default_clbk = function(value)
                params.callback(value, item)
            end
        })
    -- if params.selected was passed, the game already did the selection in RaidGUIControlStepper:init()
    -- if not, but params.value, we have to do it now...
    if params.selected == nil and params.value ~= nil then
        item:set_value_and_render(params.value, true) -- set value, skip animation
    end
    return item
end

function BLTMenu:GetCorrectSliderValue(value, min, max)
    return (value - min) / (max - min) * 100
end

function BLTMenu:Slider(params)
    params = clone(params)
    local item
    local max = params.max or 100
    local min = params.min or 0
    params.max_display_value = max
    params.min_display_value = min
    params.value_format = params.value_format or "%.2f"
    if params.value then
        params.value = self:GetCorrectSliderValue(params.value, min, max)
    end
    if params.default_value then
        params.default_value = self:GetCorrectSliderValue(params.default_value, min, max)
    end

    item = BLTMenu.CreateSimple(self, "slider", params,
        {
            no_clone = true,
            text_key = "description",
            clbk_key = "on_value_change_callback",
            default_clbk = function(value)
                params.callback(tonumber(item._value_label:text()), item)
            end
        })
    item._is_slider = true
    return item
end

function BLTMenu:Tabs(params)
    params = clone(params)

    if params.localize == nil then
        params.localize = true
    end
    if params.upper == nil then
        params.upper = true
    end

    params.dont_trigger_special_buttons = params.dont_trigger_special_buttons or true --no idea what this does
    params.tabs_params = params.tabs or { { text = "NO TABS" } }
    params.callback = params.callback or callback(self, self, "SetPage")
    params.initial_tab_idx = params.selected_tab
    params.tab_width = params.tab_width or 160

    self.default_page = params.selected_tab or "1"
    if params.tabs then
        for _, tab in pairs(params.tabs) do
            if tab.text then
                local localize = tab.localize or (params.localize and tab.localize ~= false)
                local upper = tab.upper or (params.upper and tab.upper ~= false)
                tab.text = localize and managers.localization:to_upper_text(tab.text) or upper and string.upper(tab.text) or
                tab.text
            end
        end
    end

    local item
    item = BLTMenu.CreateSimple(self, "tabs", params,
        {
            no_clone = true,
            text_key = false,
            default_clbk = function(tab_selected)
                params.callback(tab_selected, item)
            end
        })
    return item
end

function BLTMenu:Panel(params)
    params = clone(params)
    local item
    params.callback = nil
    params.text = nil
    item = BLTMenu.CreateSimple(self, "panel", params, { no_clone = true, text_key = false })
    item.ctrls = item.ctrls or {}
    return item
end

function BLTMenu:ColorButton(params)
    local preview
    local btn_params = clone(params)
    local btn
    btn_params.callback = function()
        BLT.Dialogs:Color():Show({
            title = btn_params.override_title or
            btn_params.localize ~= false and managers.localization:text(btn_params.text) or btn_params.text,
            color = btn._params.value,
            force = true,
            callback = function(color)
                btn._params.value = color
                if alive(preview) then
                    preview:set_color(color)
                end
                if params.callback then
                    params.callback(color, btn)
                end
            end
        })
    end
    btn = BLTMenu.Button(self, btn_params)
    preview = btn._object_text:parent():bitmap({
        name = "preview",
        w = 24,
        h = 24,
        x = -26,
        rotation = 360,
        texture = "ui/atlas/menu/raid_atlas_menu",
        texture_rect = { 765, 679, 33, 33 },
        color = params.value
    })
    preview:set_center_y(preview:parent():h() / 2)
    return btn
end

function BLTMenu:KeyBind(params)
    params = clone(params)
    local id = params.keybind_id or ""
    --doing this because for some reason lgl thought it's a good idea to put the text of the item inside keybind_params
    --like why aren't all items just use a parameter like 'text' sigh
    if params.localize == nil then
        params.localize = true
    end
    if params.upper == nil then
        params.upper = true
    end

    params.text = params.text or ""
    if not params.localize then
        params.text = params.upper and string.upper(params.text) or params.text
    end
    params.keybind_w = params.keybind_w or 120
    params.keybind_params = {
        binding = BLT.Keybinds:get_keybind(id):Key() or '',
        connection_name = id,
        text_id = params.text,
        localize = params.localize,
        name = id,
        button = id
    }
    BLTMenu.CreateSimple(self, "keybind", params, { no_clone = true })
end

function BLTMenu:ForEachValue(items, value_func)
    if value_func then
        for _, item in pairs(items) do
            if item.visible and item:visible() then
                value_func(item)
            end
        end
    end
end

function BLTMenu:ResetValues(items)
    self:ForEachValue(items or self._all_ctrls, function(item)
        if item._params.default_value then
            item:set_value(item._params.default_value)
            item:_on_value_changed()
        end
    end)
end

function BLTMenu:ReloadMenu(menu)
    managers.raid_menu:on_escape()
    managers.raid_menu:open_menu(menu or self._name)
end


--Basically all the shit that was in mods_menu, view_mod and download_manager but instead of fucking repeating it.
BLTCustomMenu = BLTCustomMenu or class(RaidGuiBase)
function BLTCustomMenu:init(ws, fullscreen_ws, node, name)
    self._ws = ws
    self._fullscreen_ws = fullscreen_ws
    self._fullscreen_panel = self._fullscreen_ws:panel():panel({})
    self._panel = self._ws:panel():panel({ layer = 20 })
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
    BLT.Mods:Save()
end

function BLTCustomMenu:mouse_pressed(o, button, x, y)
    BLTCustomMenu.super.mouse_pressed(self, o, button, x, y)
    local result = false

    for _, item in ipairs(self._buttons) do
        if item:inside(x, y) then
            if item.mouse_clicked then
                result = item:mouse_clicked(button, x, y)
            end
            break
        end
    end

    if button == Idstring("0") then
        for _, item in ipairs(self._buttons) do
            if item:inside(x, y) then
                if item:parameters().callback then
                    item:parameters().callback()
                end
                managers.menu_component:post_event("menu_enter")
                return true
            end
        end
    end

    if alive(self._scroll) then
        return self._scroll:mouse_pressed(o, button, x, y)
    end

    return result
end

function BLTCustomMenu:mouse_moved(o, x, y)
    if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
        return false
    end
    BLTCustomMenu.super.mouse_moved(self, o, x, y)

    local used, pointer

    local inside_scroll = alive(self._scroll) and self._scroll:panel():inside(x, y)
    for _, item in ipairs(self._buttons) do
        if not used and item:inside(x, y) and inside_scroll then
            item:set_highlight(true)
            used, pointer = true, "link"
        else
            item:set_highlight(false)
        end
    end

    if alive(self._scroll) and not used then
        used, pointer = self._scroll:mouse_moved(o, x, y)
    end

    return used, pointer
end

function BLTCustomMenu:mouse_clicked(o, button, x, y)
    if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
        return false
    end

    BLTCustomMenu.super.mouse_clicked(self, o, button, x, y)

    if alive(self._scroll) then
        return self._scroll:mouse_clicked(o, button, x, y)
    end
end

function BLTCustomMenu:mouse_released(o, button, x, y)
    if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
        return false
    end

    BLTCustomMenu.super.mouse_released(self, o, button, x, y)
    if alive(self._scroll) then
        return self._scroll:mouse_released(button, x, y)
    end
end

function BLTCustomMenu:mouse_wheel_up(x, y)
    if alive(self._scroll) then
        self._scroll:scroll(x, y, 1)
    end
end

function BLTCustomMenu:mouse_wheel_down(x, y)
    if alive(self._scroll) then
        self._scroll:scroll(x, y, -1)
    end
end

function BLTCustomMenu:make_fine_text(text)
    if not alive(text) then
        return
    end
    local x, y, w, h = text:text_rect()
    text:set_size(w, h)
    text:set_position(math.round(text:x()), math.round(text:y()))
end



-------------------------------------------------------------------------------
-- Adds a back button to a menu

Hooks:Add("MenuComponentManagerInitialize", "RaidBackButton.MenuComponentManagerInitialize", function(self)
    self._active_components.raid_back_button = { create = callback(self, self, "create_raid_back_button"), close =
    callback(self, self, "remove_raid_back_button") }
end)

function MenuComponentManager:remove_raid_back_button(node)
    --no need to lol
end

function MenuComponentManager:create_raid_back_button(node)
    if not node then
        return
    end
    RaidGuiBase:set_legend({
        controller = { "menu_legend_back" },
        keyboard = { { key = "footer_back", callback = RaidGuiBase._on_legend_pc_back } },
    })
end
