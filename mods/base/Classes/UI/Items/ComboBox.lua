BLT.Items.ComboBox = BLT.Items.ComboBox or class(BLT.Items.Item)
local ComboBox = BLT.Items.ComboBox
ComboBox.type_name = "ComboBox"
function ComboBox:Init()
    self.size_by_text = false
    self.items = self.items or {}
    self.searchbox = false -- self.searchbox == nil and true or self.searchbox
    ComboBox.super.Init(self)
    local text = self.items[self.value]
    if type(text) == "table" then
        text = text.text
    end
    local control_size = self.panel:w() * self.control_slice
    local combo_bg = self.panel:rect({
        name = "combo_bg",
        w = control_size,
        alpha = 0,
        h = self.items_size,
        layer = 1,
        color = self:GetForeground(),
    })
    self._textbox = BLT.Items.TextBoxBase:new(self, {
        panel = self.panel,
        lines = 1,
        align = self.textbox_align,
        line_color = self.line_color or self.highlight_color,
        w = self.panel:w() * (self.text == nil and 1 or self.control_slice),
        update_text = callback(self._list, self._list, "update_search", true),
        value = self.localized_items and text and managers.localization:text(tostring(text)) or
        type(text) ~= "nil" and tostring(text) or "",
    })
    self._textbox:PostInit()
    combo_bg:set_right(self.panel:w())
    self.icon = self.panel:bitmap({
        name = "icon_arrow",
        w = self.items_size - 6,
        h = self.items_size - 6,
        texture = "ui/atlas/skilltree/raid_atlas_skills",
        texture_rect = { 421, 93, 18, 18 },
        color = self:GetForeground(),
        layer = 2,
    })
    self.icon:set_right(combo_bg:right() - 2)
    self.icon:set_center_y(self._textbox.panel:center_y() - 2)
end

function ComboBox:ContextMenuCallback(item)
    self:SetSelectedItem(item, true)
end

function ComboBox:SetItems(items)
    self.items = items or {}
    self._list:update_search()
end

function ComboBox:SetValue(value, run_callback, no_items_clbk)
    if not self:alive() then
        return false
    end
    local v = self.items[value]
    if run_callback and type(v) == "table" and not no_items_clbk and v.callback then
        self:RunCallback(v.callback)
    end
    if type(v) == "table" then
        v = v.text
    end
    if alive(self.panel) then
        self._textbox:Text():set_text(self.localized_items and v and managers.localization:text(tostring(v)) or
        type(v) ~= "nil" and tostring(v) or "")
    end
    ComboBox.super.SetValue(self, value, run_callback)
    return true
end

function ComboBox:SetSelectedItem(value, ...)
    self:SetValue(table.get_key(self.items, value), ...)
end

function ComboBox:SelectedItem()
    return self.items[self.value]
end

function ComboBox:DoHighlight(highlight)
    ComboBox.super.DoHighlight(self, highlight)
    self._textbox:DoHighlight(highlight)
    if self.icon then
        play_color(self.icon, self:GetForeground(highlight))
    end
end

function ComboBox:MousePressed(button, x, y)
    if not self:MouseCheck(true) then
        return
    end
    if not self.menu._openlist and self.parent.panel:inside(x, y) and self.panel:inside(x, y) then
        if button == Idstring("0") then
            self._list:update_search()
            self._list:show()
            return true
        end
    end
end
