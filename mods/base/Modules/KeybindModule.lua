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
	if not self._config.keybind_id then 
		self:log("[ERROR] Keybind does not contain a definition for keybind_id!")
		return
	end
	self._config.run_in_menu = self._config.run_in_menu or true
	self._config.run_in_game = self._config.run_in_game or true
	BLT.Keybinds:register_keybind(self._mod, self._config)
end

BLT:RegisterModule(KeybindModule.type_name, KeybindModule)