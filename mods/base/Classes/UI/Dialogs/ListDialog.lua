ListDialog = ListDialog or class(MenuDialog)
ListDialog.type_name = "ListDialog"
ListDialog._no_reshaping_menu = true

function ListDialog:init(params, menu)
    if self.type_name == ListDialog.type_name then
        params = params and clone(params) or {}
    end

    menu = menu or BLT.Dialogs:Menu()

    local w, h = params.w, params.h
    params.h = nil

    ListDialog.super.init(self, table.merge({
        h = params.main_h or 32,
        w = 1000,
        items_size = 32,
        offset = 0,
        auto_height = false,
        align_method = "grid",
        auto_align = true
    }, params), menu)

    params.h = h

    self._list_menu = menu:Menu(table.merge({
        name = "List",
        w = 1000,
        h = params.h and params.h - self._menu.h or 700,
        items_size = 28,
        auto_foreground = true,
        no_animating = true,
        auto_align = false,
        background_color = self._menu.background_color,
        accent_color = self._menu.accent_color,
        position = params.position or "Center",
        visible = false,
    }, params))

    self._menus = { self._list_menu }
    self._menu:Panel():set_leftbottom(self._list_menu:Panel():left(), self._list_menu:Panel():top() - 1)
end

function ListDialog:CreateShortcuts(params)
    local offset = { 4, 0 }
    local bw = self._menu:Toggle({
        name = "Limit",
        --w = bw, -- dafuq?
        offset = offset,
        text = ">|",
        help = "blt_limit_results",
        help_localized = true,
        size_by_text = true,
        value = self._limit,
        callback = function(menu, item)
            self._limit = item:Value()
            self:MakeListItems()
        end,
        label = "temp"
    }):Width()
    self._menu:Toggle({
        name = "CaseSensitive",
        w = bw,
        offset = offset,
        text = "Aa",
        help = "blt_match_case",
        help_localized = true,
        value = self._case_sensitive,
        callback = function(menu, item)
            self._case_sensitive = item:Value()
            self:MakeListItems()
        end,
        label = "temp"
    })
    return offset, bw
end

function ListDialog:_Show(params)
    if not self:basic_show(params) then
        return
    end
    self._filter = {}
    self._case_sensitive = params.case_sensitive
    self._limit = NotNil(params.limit, true)
    self._list = params.list
    local offset, bw = self:CreateShortcuts(params)
    local close = self._menu:ImageButton({
        name = "Close",
        w = bw,
        h = self._menu.items_size,
        offset = offset,
        icon_w = 24,
        icon_h = 24,
        img_rot = 45,
        texture = "ui/atlas/menu/raid_atlas_menu",
        texture_rect = { 761, 721, 18, 18 },
        callback = callback(self, self, "hide"),
        label = "temp"
    })

    self._menu:TextBox({
        name = "Search",
        w = self._menu:ItemsWidth() - close:Right() - offset[1],
        control_slice = 0.86,
        index = 1,
        text = "blt_search",
        localized = true,
        callback = callback(self, self, "Search"),
        label = "temp"
    })
    if params.sort ~= false then
        table.sort(params.list, function(a, b)
            return (type(a) == "table" and a.name or a) < (type(b) == "table" and b.name or b)
        end)
    end
    self:MakeListItems(params)
end

function ListDialog:ItemsCount()
    return #self._list_menu:Items()
end

function ListDialog:SearchCheck(t)
    if #self._filter == 0 then
        return true
    end
    local match
    for _, s in pairs(self._filter) do
        match = (self._case_sensitive and string.match(t, s) or not self._case_sensitive and string.match(t:lower(), s:lower()))
    end
    return match
end

function ListDialog:MakeListItems(params)
    self._list_menu:ClearItems("temp2")
    local case = self._case_sensitive
    local limit = self._limit
    local groups = {}
    local i = 0
    for _, v in pairs(self._list) do
        local t = type(v) == "table" and v.name or v
        if self:SearchCheck(t) then
            i = i + 1
            if limit and i >= 250 then
                break
            end
            local menu = self._list_menu
            if type(v) == "table" and v.create_group then
                menu = groups[v.create_group] or self._list_menu:Group({
                    auto_align = false,
                    name = v.create_group,
                    text = v.create_group,
                    label = "temp2"
                })
                groups[v.create_group] = menu
            end
            menu:Button(table.merge(type(v) == "table" and v or {}, {
                name = t,
                text = t,
                callback = function(menu, item)
                    if self._callback then
                        self._callback(v)
                    end
                end,
                label = "temp2"
            }))
        end
    end

    self:show_dialog()
    self._list_menu:AlignItems(true)
end

function ListDialog:ReloadInterface()
    self._list_menu:AlignItems(true)
end

function ListDialog:Search(menu, item)
    self._filter = {}
    for _, s in pairs(string.split(item:Value(), ",")) do
        table.insert(self._filter, s)
    end
    self:MakeListItems()
end

function ListDialog:run_callback(clbk)
end

function ListDialog:should_close()
    return self._menu:ShouldClose() or self._list_menu:ShouldClose()
end

function ListDialog:hide(yes)
    self._list_menu:SetVisible(false)
    return ListDialog.super.hide(self, yes)
end
