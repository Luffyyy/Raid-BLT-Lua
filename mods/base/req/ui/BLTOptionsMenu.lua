BLTOptionsMenu = BLTOptionsMenu or class(BLTMenu)
function BLTOptionsMenu:Init(root)
    local btn = self:Button({ --no idea where callback is at
        name = "test",
        text = "WIP :("
    })
end  

--Let the game know what the class is for.
Hooks:Add("MenuComponentManagerInitialize", "BLTOptionsMenu.MenuComponentManagerInitialize", function(self)
    RaidMenuHelper:CreateMenu({
		name = "blt_options", --name of the menu
		name_id = "blt_options_menu_lua_mod_options", --name_id / title
		back_callback = "perform_blt_save",
        inject_list = "raid_menu_left_options", --inject a button into a menu's list
        class = BLTOptionsMenu, --the class we just made, duh
		inject_after = "network" --inject where? if not defined last place.
	})
end)