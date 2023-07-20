BLTOptionsMenu = BLTOptionsMenu or class(BLTMenu)
function BLTOptionsMenu:Init(root)
    self:Title({
        text = "menu_header_options_main_screen_name"
    })
    self:SubTitle({
        text = "blt_options_menu_lua_mod_options"
    })
end

Hooks:Add("MenuComponentManagerInitialize", "BLTOptionsMenu.MenuComponentManagerInitialize", function(self)
    RaidMenuHelper:CreateMenu({
        name = BLTModManager.Constants.BLTOptions,
        name_id = "blt_options_menu_lua_mod_options",
        inject_list = "raid_menu_left_options",
        class = BLTOptionsMenu,
        inject_after = "network"
    })
end)
