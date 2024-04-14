SimpleListDialog = SimpleListDialog or class(ListDialog)
SimpleListDialog.type_name = "SimpleListDialog"
function SimpleListDialog:init(params, menu)
    if self.type_name == SimpleListDialog.type_name then
        params = params and clone(params) or {}
    end

    params.w = 600
    params.h = 700
    params.main_h = 70

    SimpleListDialog.super.init(self, params, menu)
end

function SimpleListDialog:_Show(params)
    if not self:basic_show(params) then
        return
    end

    params = params or {}

    if self.type_name == SimpleSelectListDialog.type_name then
        self._single_select = params.single_select or false
        self._allow_multi_insert = params.allow_multi_insert or false
        self._selected_list = params.selected_list or {}
    end

    self._filter = {}
    self._case_sensitive = NotNil(params.case_sensitive, false)
    self._limit = NotNil(params.limit, true)
    self._list = params.list
    local bs = self._menu.h + 4
    local tw = self._menu.w - (bs * 2)

    self._menu:TextBox({
        name = "Search",
        w = tw,
        control_slice = 0.98,
        text = false,
        callback = callback(self, self, "Search"),
        label = "temp"
    })

    local close = self._menu:ImageButton({
        name = "Close",
        w = bs,
        h = self._menu.items_size,
        icon_w = 20,
        icon_h = 20,
        img_rot = 45,
        position = "RightTop",
        texture = "ui/atlas/raid_atlas_menu",
        texture_rect = { 761, 721, 18, 18 },
        callback = callback(self, self, "hide", false),
        label = "temp"
    })

    self._menu:ImageButton({
        name = "Apply",
        w = bs,
        h = self._menu.items_size,
        icon_w = 24,
        icon_h = 24,
        position = function(item)
            item:Panel():set_righttop(close:Panel():position())
        end,
        texture = "ui/atlas/raid_atlas_menu",
        texture_rect = { 341, 997, 22, 22 },
        callback = callback(self, self, "hide", true),
        label = "temp"
    })
    if params.sort ~= false then
        table.sort(params.list, function(a, b)
            return (type(a) == "table" and a.name or a) < (type(b) == "table" and b.name or b)
        end)
    end
    self:MakeListItems(params)
end
