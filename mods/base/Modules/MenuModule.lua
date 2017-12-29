MenuModule = MenuModule or class(ModuleBase)
MenuModule.type_name = "menu"

function MenuModule:init(core_mod, config)
    if not MenuModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()

    return true
end

function MenuModule:Load()
	local data = self._config
	if not data.name then
		self:log("[ERROR] Creation of menu at path %s has failed, no menu name given.")
		return
	end
	RaidMenuHelper:ConvertXMLData(data)
	RaidMenuHelper:LoadMenu(data, self._mod)
end

BLT:RegisterModule(MenuModule.type_name, MenuModule)