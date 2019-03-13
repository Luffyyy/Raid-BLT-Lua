KeybindsModule = KeybindsModule or class(ModuleBase)

KeybindsModule.type_name = "Keybinds"

function KeybindsModule:post_init(...)
    if not KeybindsModule.super.post_init(self, ...) then
        return false
    end

    self:Load()

    return true
end

function KeybindsModule:Load()
    for _, keybind in ipairs(self._config) do
        if keybind._meta == "keybind" then
            if not keybind.keybind_id then
                self:log("[ERROR] Keybind does not contain a definition for keybind_id!")
                return
            end
            keybind.run_in_menu = keybind.run_in_menu or true
            keybind.run_in_game = keybind.run_in_game or true
            BLT.Keybinds:register_keybind(self._mod, keybind)
        end
    end
end

BLT:RegisterModule(KeybindsModule.type_name, KeybindsModule)