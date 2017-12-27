BLTOptionsMenu = BLTOptionsMenu or class(BLTMenu)
function BLTOptionsMenu:Init(root)
    self:Title({text = "menu_header_options_main_screen_name"})
    self:SubTitle({text = "blt_options_menu_lua_mod_options"})

    local items = {}
    for _, lang in ipairs(BLT.Localization:languages()) do
		table.insert(items, {
            text = managers.localization:to_upper_text("blt_language_"..tostring(lang.language)),
            value = tostring(lang.language),
        })
	end

    self:MultiChoice({
        name = "blt_localization_choose",
        text = "blt_language_select",
        callback = callback(self, self, "blt_choose_language"),
        value = tostring(BLT.Localization:get_language().language),
        enabled = #items > 1,
        items = items
    })

    self:Label({h = 36})    
end

function BLTOptionsMenu:blt_choose_language(item)
    if BLT.Localization then
		BLT.Localization:set_language(item.value)
    end
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