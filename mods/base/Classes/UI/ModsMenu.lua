BLTModsMenu = BLTModsMenu or class()
function BLTModsMenu:init()
    MenuUI:new({
        name = "BLTMods",
        layer = 1000,
        offset = 6,
        show_help_time = 0.1,
        animate_toggle = true,
        auto_foreground = true,
        create_items = ClassClbk(self, "CreateItems"),
    })
end

function BLTModsMenu:SetEnabled(enabled)
    local opened = BLT.Dialogs:DialogOpened(self)
    if enabled then
        if not opened then
            BLT.Dialogs:ShowDialog(self)
            self._menu:Enable()
        end
    elseif opened then
        BLT.Dialogs:CloseDialog(self)
        self._menu:Disable()
    end
end

function BLTModsMenu:should_close()
    return self._menu:ShouldClose()
end

function BLTModsMenu:hide()
    self:SetEnabled(false)
    return true
end

function BLTModsMenu:CreateItems(menu)
    self._menu = menu

    self._holder = menu:Menu({
        name = "Main",
        accent_color = Color("e22626"),
        private = { background_color = Color(0.8, 0.2, 0.2, 0.2) },
        items_size = 23,
    })
    menu._panel:rect({
        name = "title_bg",
        layer = 2,
        color = Color("e22626"),
        h = 48,
    })
    local y = 6
    local text = self._holder:Divider({
        name = "title",
        text = "blt_mods_manager",
        localized = true,
        items_size = 38,
        position = { 8, y },
        count_as_aligned = true
    })
    local close = self._holder:Button({
        name = "Close",
        text = "blt_close",
        size_by_text = true,
        localized = true,
        items_size = 32,
        position = function(item)
            item:SetPositionByString("RightTop")
            item:Panel():move(-8, y)
        end,
        callback = ClassClbk(self, "SetEnabled", false)
    })
    local updates = self._holder:Button({
        name = "Updates",
        text = "blt_updates",
        size_by_text = true,
        localized = true,
        items_size = 32,
        position = function(item)
            item:Panel():set_righttop(close:Panel():left() - 8, y)
        end,
        callback = ClassClbk(self, "GoToUpdates")
    })
    self._holder:TextBox({
        name = "search",
        text = false,
        w = 300,
        line_color = self._holder.foreground,
        control_slice = 1,
        items_size = 32,
        position = function(item)
            item:SetPositionByString("Center")
            item:Panel():set_y(y)
        end,
        callback = ClassClbk(self, "SearchMods")
    })
    self._list = self._holder:Menu({
        name = "ModList",
        h = self._holder:ItemsHeight() - text:OuterHeight() - (self._holder.offset[2] * 2) - 10,
        private = { offset = 0 },
        position = function(item)
            item:SetPositionByString("CenterBottom")
            item:Panel():move(0, -10)
        end,
        auto_align = false,
        animate_align = true,
        align_method = "grid",
    })
    for _, mod in pairs(table.sorted_copy(BLT.Mods:Mods(), self.ModSort)) do
        self:AddMod(mod, "normal")
    end
    self._list:AlignItems(true)
end

function BLTModsMenu:GoToUpdates()
    self:SetEnabled(false)
    BLT.UpdatesMenu:SetEnabled(true)
end

function BLTModsMenu.ModSort(mod1, mod2)
    if mod1:GetId() == "base" then
        return true
    elseif mod2:GetId() == "base" then
        return false
    else
        return mod1:GetName():lower() < mod2:GetName():lower()
    end
end

function BLTModsMenu:Text(mod_item, t, opt)
    opt = opt or {}
    return mod_item:Divider(table.merge({
        text_vertical = "top",
        text = t,
    }, opt))
end

function BLTModsMenu:Button(mod_item, t, clbk, enabled, opt)
    opt = opt or {}
    mod_item:Button(table.merge({
        callback = clbk,
        enabled = enabled,
        localized = true,
        text = t
    }, opt))
end

function BLTModsMenu:AddMod(mod, type)
    local loc = managers.localization
    local disabled_mods = BLT.Options:GetValue("DisabledMods")
    local name = mod.name or "Missing name?"
    local blt_mod = type == "normal"
    local color = blt_mod and Color("3f4756") or type == "custom" and Color(0, 0.25, 1) or Color(0.1, 0.6, 0.1)
    local s = (self._list:ItemsWidth() / 5) - self._list:Offset()[1]

    local color_override = mod:GetColor()
    if color_override then
        color = color_override
    end

    local concol = color:contrast():with_alpha(0.1)
    local mod_item = self._list:Menu({
        name = name,
        label = mod,
        w = s - 1,
        h = s - 1,
        index = mod:GetId() == "base" and 1 or nil,
        scrollbar = false,
        auto_align = false,
        accent_color = concol,
        highlight_color = concol,
        background_color = color:with_alpha(0.8)
    })
    self._list:SetScrollSpeed(mod_item:Height())
    if mod:Errors() then
        self:Text(mod_item, loc:text("blt_mod_failed_load"))
    elseif not mod:IsEnabled() then
        self:Text(mod_item, loc:text("blt_mod_no_load"))
    end

    local img = mod._config.image
    img = img and DB:has(Idstring("texture"), Idstring(mod._config.image)) and img or nil
    local img_item = mod_item:Image({
        name = "Image",
        w = 100,
        h = 100,
        icon_w = 100,
        icon_h = 100,
        foreground = Color.white,
        auto_foreground = mod._config.auto_image_color or not img,
        count_as_aligned = true,
        texture_rect = not img and { 353, 894, 100, 100 },
        texture = img or "ui/atlas/menu/raid_atlas_menu",
        position = "center_x"
    })
    local t = self:Text(mod_item, tostring(name), { name = "Title", offset = { mod_item.offset[1], 16 } })
    self:Text(mod_item, loc:text("blt_mod_author", { author = mod:GetAuthor() }))
    mod_item:Toggle({
        name = "Enabled",
        text = false,
        enabled = not mod.cannot_be_disabled,
        w = 32,
        h = 32,
        offset = 0,
        items_size = 32,
        highlight_color = Color.transparent,
        value = disabled_mods[mod.path] ~= true,
        callback = ClassClbk(self, "SetModEnabled", mod),
        position = function(item)
            item:SetPositionByString("TopRight")
            item:Panel():move(-4, 1)
        end
    })
    self:Button(mod_item, "blt_more_info", ClassClbk(self, "ViewMoreInfoMod", mod))
    if mod._main_update and mod._main_update:HasPage() then
        self:Button(mod_item, "blt_visit_page", ClassClbk(self, "ViewMod", mod))
    end
    self:UpdateTitle(mod)
end

function BLTModsMenu:UpdateTitle(mod)
    local mod_item = self._list:GetItemByLabel(mod)
    if mod_item then
        local title = mod_item:GetItem("Title")
        title:SetText((mod.name or "Missing name?") ..
            (mod._main_update and mod._main_update.version and "(" .. mod._main_update.version .. ")" or ""))
    end
end

function BLTModsMenu:SetModEnabled(mod)
    local disabled_mods = BLT.Options:GetValue("DisabledMods")
    local path = mod.path
    if disabled_mods[path] then
        disabled_mods[path] = nil
    else
        disabled_mods[path] = true
    end
    BLT.Options:Save()
end

function BLTModsMenu:SearchMods(menu, item)
    for _, mod_item in pairs(self._list._my_items) do
        local search = tostring(item:Value()):lower()
        local visible = tostring(mod_item.name):lower():match(search) ~= nil
        if search == " " or search:len() < 1 then
            visible = true
        end
        mod_item:SetVisible(visible)
    end
    self._list:AlignItems()
end

function BLTModsMenu:ViewMod(mod)
    if mod._main_update then
        mod._main_update:ViewMod()
    end
end

function BLTModsMenu:ViewMoreInfoMod(mod)
    BLT.Dialogs:Simple():Show({
        w = 1300,
        create_items = function(menu)
            local holder = menu:Menu({
                auto_height = true,
                scroll_color = self._menu.foreground,
                scrollbar = true,
                max_height = 700,
            })
            holder:Divider({ size_by_text = true, text = mod:GetDeveloperInfo() })
        end
    })
end

Hooks:Add("MenuComponentManagerInitialize", "BLTModsGui.MenuComponentManagerInitialize", function(self)
    RaidMenuHelper:InjectButtons("raid_menu_left_options", nil, {
        RaidMenuHelper:PrepareListButton("blt_options_menu_blt_mods", true,
            RaidMenuHelper:MakeClbk("OpenBLTModsMenu", ClassClbk(BLT.ModsMenu, "SetEnabled", true)))
    }, true)
end)
