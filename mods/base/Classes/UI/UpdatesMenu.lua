BLTUpdatesMenu = BLTUpdatesMenu or class()
function BLTUpdatesMenu:init()
    MenuUI:new({
        name = "BLTUpdates",
        layer = 1000,
        offset = 6,
        show_help_time = 0.1,
        animate_toggle = true,
        auto_foreground = true,
        create_items = ClassClbk(self, "CreateItems"),
    })
end

function BLTUpdatesMenu:SetEnabled(enabled)
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

function BLTUpdatesMenu:should_close()
    return self._menu:ShouldClose()
end

function BLTUpdatesMenu:hide()
    self:SetEnabled(false)
    return true
end

function BLTUpdatesMenu:CreateItems(menu)
    self._menu = menu
    self._downloading_string = managers.localization:text("blt_downloading")

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
        text = "blt_updates_manager",
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
    local go_to_mods = self._holder:Button({
        name = "Mods",
        text = "blt_mods",
        size_by_text = true,
        localized = true,
        items_size = 32,
        position = function(item)
            item:Panel():set_righttop(close:Panel():left() - 8, y)
        end,
        callback = ClassClbk(self, "GoToMods")
    })
    local upall = self._holder:Button({
        name = "UpdateAll",
        text = "blt_update_all",
        size_by_text = true,
        localized = true,
        items_size = 32,
        position = function(item)
            item:Panel():set_righttop(go_to_mods:Panel():left() - 8, y)
        end,
        callback = ClassClbk(self, "UpdateAll", true),
        second_callback = ClassClbk(self, "UpdateAll")
    })
    local quick_restart = self._holder:Button({
        name = "QuickRestart",
        text = "blt_quick_restart",
        size_by_text = true,
        localized = true,
        items_size = 32,
        position = function(item)
            item:Panel():set_righttop(upall:Panel():left() - 8, y)
        end,
        callback = ClassClbk(self, "QuickRestart")
    })
    self._holder:Toggle({
        name = "ImportantNotice",
        text = "blt_important_notice",
        value = BLT.Options:GetValue("ImportantNotice"),
        size_by_text = true,
        localized = true,
        items_size = 32,
        position = function(item)
            item:Panel():set_righttop(quick_restart:Panel():left() - 8, y)
        end,
        callback = ClassClbk(self, "SetShowImportantUpdatesNotice")
    })
    self._list = self._holder:Menu({
        name = "UpdateList",
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
    if BLT.Updates:UpdatesAvailable() then
        for _, update in pairs(BLT.Updates:GetAvailableUpdates()) do
            self:AddUpdate(update, "normal", false)
        end
    end
    self._list:AlignItems(true)
end

function BLTUpdatesMenu:QuickRestart()
    if setup and setup.quit_to_main_menu then
        setup.exit_to_main_menu = true
        setup:quit_to_main_menu() -- reloads lua
    end
end

function BLTUpdatesMenu:GoToMods()
    self:SetEnabled(false)
    BLT.ModsMenu:SetEnabled(true)
end

function BLTUpdatesMenu:Text(update_item, t, opt)
    opt = opt or {}
    return update_item:Divider(table.merge({
        text_vertical = "top",
        text = t,
    }, opt))
end

function BLTUpdatesMenu:Button(update_item, t, clbk, enabled, opt)
    opt = opt or {}
    update_item:Button(table.merge({
        callback = clbk,
        enabled = enabled,
        localized = true,
        text = t
    }, opt))
end

function BLTUpdatesMenu:AddUpdate(update, mod_type, realign)
    local loc = managers.localization
    local mod = update._mod
    local name = update.display_name or mod.name
    local blt_mod = mod_type == "normal"
    local color = blt_mod and Color("3f4756") or type == "custom" and Color(0, 0.25, 1) or Color(0.1, 0.6, 0.1)
    local s = (self._list:ItemsWidth() / 5) - self._list:Offset()[1]

    local color_override = mod:GetColor()
    if color_override then
        color = color_override
    end

    local concol = color:contrast():with_alpha(0.1)
    local update_item = self._list:Menu({
        name = name,
        label = update,
        w = s - 1,
        h = s - 1,
        index = mod:GetId() == "base" and 1 or nil,
        scrollbar = false,
        auto_align = false,
        accent_color = concol,
        highlight_color = concol,
        background_color = color:with_alpha(0.8)
    })
    self._list:SetScrollSpeed(update_item:Height())

    local img = mod._config.image
    img = img and DB:has(Idstring("texture"), Idstring(mod._config.image)) and img or nil
    local img_item = update_item:Image({
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
    local t = self:Text(update_item, tostring(name), { name = "Title", offset = { update_item.offset[1], 16 } })
    self:Text(update_item, "", { name = "Status" })
    update_item:Panel():rect({
        name = "DownloadProgress",
        color = color:contrast():with_alpha(0.25),
        w = 0,
    })

    if update:HasPage() then
        self:Button(update_item, "blt_show_mod_changelog", ClassClbk(self, "ShowModChangelog", update), true)
    end
    self:Button(update_item, "blt_updates_download_now", ClassClbk(self, "BeginUpdateDownload", update), true,
        { name = "Download" })
    self:SetUpdateStatus(update_item,
        loc:text("blt_waiting_update") .. (update._new_version and "(" .. update._new_version .. ")" or ""),
        true)

    self:UpdateTitle(update)

    if realign then
        self._list:AlignItems(true)
    end
end

function BLTUpdatesMenu:ShowModChangelog(update)
    update:ViewModChangelog()

end

function BLTUpdatesMenu:UpdateTitle(update)
    local update_item = self._list:GetItemByLabel(update)
    if update_item then
        local title = update_item:GetItem("Title")
        title:SetText((update.display_name or update._mod.name) ..
            (update.version and "(" .. update.version .. ")" or ""))
    end
end

function BLTUpdatesMenu:UpdateAll(no_dialog)
    local tbl = {}
    for _, update_item in pairs(self._list._my_items) do
        local download = update_item:GetItem("Download")
        if download:Enabled() then
            table.insert(tbl, { name = update_item.name, value = update_item })
        end
    end
    if no_dialog == true then
        self:UpdateAllByList(tbl)
    else
        BLT.Dialogs:SimpleSelectList():Show({
            force = true,
            list = tbl,
            selected_list = tbl,
            callback = ClassClbk(self,
                "UpdateAllByList")
        })
    end
end

function BLTUpdatesMenu:UpdateAllByList(list)
    for _, item in pairs(list) do
        local download = item.value:GetItem("Download")
        if download:Enabled() and not item.value.label:DisallowsUpdate() then
            download:SetEnabled(false)
            download:RunCallback()
        end
    end
end

function BLTUpdatesMenu:SetShowImportantUpdatesNotice(menu, item)
    BLT.Options:SetValue("ImportantNotice", item:Value())
end

function BLTUpdatesMenu:BeginUpdateDownload(update)
    if update then
        self:SetUpdateStatus(self._list:GetItemByLabel(update), "blt_waiting")
        update:DownloadAssets()
    end
end

local megabytes = (1024 ^ 2)
function BLTUpdatesMenu:SetUpdateProgress(update, bytes, total_bytes)
    local update_item = self._list:GetItemByLabel(update)
    if update_item and alive(update_item) then
        local progress = bytes / total_bytes
        local mb = bytes / megabytes
        local total_mb = total_bytes / megabytes
        update_item:GetItem("Status"):SetTextLight(string.format(self._downloading_string .. "%.2f/%.2fmb(%.0f%%)", mb,
            total_mb, tostring(progress * 100)))
        update_item:Panel():child("DownloadProgress"):set_w(update_item:Panel():w() * progress)
        local downbtn = update_item:GetItem("Download")
        if downbtn:Enabled() then
            downbtn:SetEnabled(false)
        end
    end
end

function BLTUpdatesMenu:SetInstallingUpdate(update)
    local update_item = self._list:GetItemByLabel(update)
    if update_item then
        self:SetUpdateStatus(update_item, "blt_download_complete")
        update_item:Panel():child("DownloadProgress"):set_w(0)
    end
end

function BLTUpdatesMenu:SetFailedUpdate(update)
    local update_item = self._list:GetItemByLabel(update)
    if update_item then
        self:SetUpdateStatus(update_item, "blt_download_failed")
        update_item:Panel():child("DownloadProgress"):set_w(0)
    end
end

function BLTUpdatesMenu:SetUpdateDone(update)
    local update_item = self._list:GetItemByLabel(update)
    if update_item then
        self:SetUpdateStatus(update_item, "blt_updated")
        update_item:Panel():child("DownloadProgress"):set_w(0)
        update_item:GetItem("Download"):SetEnabled(false)
        self:UpdateTitle(update)
    end
end

function BLTUpdatesMenu:SetUpdateStatus(update_item, status, not_localized)
    if update_item then
        update_item:GetItem("Status"):SetText(not_localized and status or managers.localization:text(status))
    end
end

Hooks:Add("MenuComponentManagerInitialize", "BLTUpdatesGui.MenuComponentManagerInitialize", function(self)
    RaidMenuHelper:InjectButtons("raid_menu_left_options", nil, {
        RaidMenuHelper:PrepareListButton("blt_options_menu_blt_updates", true,
            RaidMenuHelper:MakeClbk("OpenBLTUpdatesMenu", ClassClbk(BLT.UpdatesMenu, "SetEnabled", true)))
    }, true)
end)
