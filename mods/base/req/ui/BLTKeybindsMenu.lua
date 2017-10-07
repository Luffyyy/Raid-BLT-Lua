BLTKeybindsMenu = BLTKeybindsMenu or class(BLTMenu)
function BLTKeybindsMenu:Init(root)
    local btn = self:Button({
        name = "test",
        text = "WIP :("
    })
end  

Hooks:Add("MenuComponentManagerInitialize", "BLTKeybindsMenu.MenuComponentManagerInitialize", function(self)
    RaidMenuHelper:CreateMenu({
		name = "blt_keybinds",
		name_id = "blt_options_menu_keybinds",
		back_callback = "perform_blt_save",
        inject_list = "raid_menu_left_options",
        class = BLTKeybindsMenu,
	})
end)