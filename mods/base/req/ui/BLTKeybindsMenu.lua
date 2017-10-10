BLTKeybindsMenu = BLTKeybindsMenu or class(BLTMenu)
function BLTKeybindsMenu:Init(root)
    self:Title({text = "menu_header_options_main_screen_name"})
    self:SubTitle({text = "blt_options_menu_keybinds"})

    self:Label({
        text = "Temporarily unavailable!",
        y_offset = 32,
        localize = false
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