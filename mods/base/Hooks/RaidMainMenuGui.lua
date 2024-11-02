Hooks:PostHook(RaidMainMenuGui, "_layout", "BLT_Farewell_Hook", function(self, ...)
    if RaidMenuCallbackHandler:is_in_main_menu() then
        if not SystemFS:exists(SavePath .. "rblt_farewell") then
            BLT:_Farewell()
            local f = io.open(SavePath .. "rblt_farewell", "w")
            if f then
                io.close(f)
            end
        end
        if not self._rblt_farewell_button then
            self._rblt_farewell_button = RaidGUIControlButtonLongPrimary:new(self._root_panel, {
                name = "rblt_farewell_button",
                text = managers.localization:text("blt_farewell_rblt_button"),
                w = 100,
                h = 50,
                x = RenderSettings.resolution.x * 0.76,
                y = RenderSettings.resolution.y * 0.85,
                on_click_callback = callback(BLT, BLT, "_Farewell")
            })
            self._root_panel:_add_control(self._rblt_farewell_button)
        else
            self._rblt_farewell_button:show()
        end
    else
        if self._rblt_farewell_button then
            self._rblt_farewell_button:hide()
        end
    end
end)