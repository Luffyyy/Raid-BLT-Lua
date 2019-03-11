KeybindModule = KeybindModule or class(ModuleBase)

KeybindModule.type_name = "Keybinds"

function KeybindModule:post_init(...)
    if not KeybindModule.super.post_init(self, ...) then
        return false
    end

    self:Load()

    return true
end

function KeybindModule:Load()
    for _, keybind in ipairs(self._config) do
        if not keybind.keybind_id then
            self:log("[ERROR] Keybind does not contain a definition for keybind_id!")
            return
        end
        keybind.run_in_menu = keybind.run_in_menu or true
        keybind.run_in_game = keybind.run_in_game or true
        BLT.Keybinds:register_keybind(self._mod, keybind)
    end
end

BLT:RegisterModule(KeybindModule.type_name, KeybindModule)