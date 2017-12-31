MenuModule = MenuModule or class(ModuleBase)
MenuModule.type_name = "menu"

function MenuModule:post_init(...)
    if not MenuModule.super.post_init(self, ...) then
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