--Deprecated!
_G.MenuHelper = _G.MenuHelper or {}
function MenuHelper:SetupMenu(menu, id) end
function MenuHelper:SetupMenuButton(menu, id, button_id) end
function MenuHelper:NewMenu(menu_id) end
function MenuHelper:GetMenu(menu_id) end
function MenuHelper:AddBackButton(menu_id) end
function MenuHelper:AddButton(button_data)end
function MenuHelper:AddDivider(divider_data) end
function MenuHelper:AddToggle(toggle_data) end
function MenuHelper:AddSlider(slider_data) end
function MenuHelper:AddMultipleChoice(multi_data) end
function MenuHelper:AddKeybinding(bind_data)end
function MenuHelper:AddInput(input_data) end
function MenuHelper:BuildMenu(menu_id, data) end
function MenuHelper:AddMenuItem(parent_menu, child_menu, name, desc, menu_position, subposition) end
function MenuHelper:LoadFromJsonFile(file_path, parent_class, data_table) end
function MenuHelper:ResetItemsToDefaultValue(item, items_table, value) end