MenuModule = MenuModule or class(ModuleBase)
MenuModule.type_name = "Menu"

function MenuModule:post_init(...)
    if not MenuModule.super.post_init(self, ...) then
        return false
    end

    self:Load()

    return true
end

function MenuModule:Load()
	local path = "<MenuModule>"
	local data = self._config
	if not data.name then
		self:LogF(LogLevel.ERROR, "Load", "Creation of menu at path '%s' has failed, no menu name given.", path)
		return
	end
	RaidMenuHelper:ConvertXMLData(data)
	RaidMenuHelper:LoadMenu(data, path, self._mod)
end

BLT:RegisterModule(MenuModule.type_name, MenuModule)