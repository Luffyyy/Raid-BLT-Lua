BLT.Items.Group = BLT.Items.Group or class(BLT.Items.Menu)
local Group = BLT.Items.Group
Group.type_name = "Group"
function Group:Init()
    Group.super.Init(self)
    self:InitBasicItem()
    self:GrowHeight()
end

function Group:InitBasicItem()
    Group.super.InitBasicItem(self)
    if not self.divider_type then
        self.toggle = self.panel:bitmap({
            name = "toggle",
            w = self.parent.items_size - 4,
            h = self.parent.items_size - 4,
            texture = "ui/atlas/skilltree/raid_atlas_skills",
            color = self:GetForeground(),
            y = 2,
            texture_rect = { self.closed and 437 or 421, self.closed and 109 or 93, 18, 18 },
            layer = 3,
            { 421, 93, 18, 18 }
        })
        self:RePositionToggle()
    end
end

function Group:RePositionToggle()
    if self:title_alive() then
        local _, _, w, _ = self.title:text_rect()
        if self.toggle and alive(self.toggle) then
            self.toggle:set_left(w + 4)
        end
    end
end

function Group:SetText(...)
    if Group.super.SetText(self, ...) then
        self:SetScrollPanelSize()
    end
    self:RePositionToggle()
end

function Group:ToggleGroup()
    if self.closed then
        self.closed = false
    else
        self.closed = true
        self.panel:set_h(self.parent.items_size)
    end
    for i, item in pairs(self._my_items) do
        if item:ParentPanel() == self:ItemsPanel() then
            item:SetVisible(not self.closed)
        end
    end
    self.toggle:set_texture_rect(self.closed and 42 or 2, self.closed and 2 or 0, 16, 16)
    self:AlignItems()
    self:SetSize(nil, nil, true)
end

function Group:MouseInside(x, y)
    return self.highlight_bg:inside(x, y)
end

function Group:MousePressed(button, x, y)
    if button == Idstring("0") and self:MouseCheck(true) then
        self:ToggleGroup()
        return true
    end
    return Group.super.MousePressed(self, button, x, y)
end

function Group:MouseMoved(x, y)
    if not Group.super.MouseMoved(self, x, y) then
        return BLT.Items.Item.MouseMoved(self, x, y)
    end
    return false
end
