BLTKeybindsMenu = BLTKeybindsMenu or class(BLTMenu)
function BLTKeybindsMenu:Init(root)
    self:Title({text = "menu_header_options_main_screen_name"})
    self:SubTitle({text = "blt_options_menu_keybinds"})
	local last_mod
	for i, bind in ipairs(BLT.Keybinds:keybinds()) do
		if bind:IsActive() and bind:ShowInMenu() then
			-- Seperate keybinds by mod
			if last_mod ~= bind:ParentMod() then
                self:Label({text = bind:ParentMod():GetName(), localize = false})
			end
            self:KeyBind({
				name = bind:Id(),
				text = bind:Name(),
                keybind_id = bind:Id(),
                x_offset = 10,
                localize = false,
            })

            last_mod = bind:ParentMod()            
		end
	end
end

function BLTKeybindsMenu:Close()
	BLT.Mods:Save()
end

Hooks:Add("MenuComponentManagerInitialize", "BLTKeybindsMenu.MenuComponentManagerInitialize", function(self)
    RaidMenuHelper:CreateMenu({
		name = "blt_keybinds",
		name_id = "blt_options_menu_keybinds",
        inject_list = "raid_menu_left_options",
        class = BLTKeybindsMenu,
	})
end)