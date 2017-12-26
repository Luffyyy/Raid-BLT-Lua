LocalizationModule = LocalizationModule or class(ModuleBase)

--Need a better name for this
LocalizationModule.type_name = "localization"

function LocalizationModule:init(core_mod, config)
    if not LocalizationModule.super.init(self, core_mod, config) then
        return false
    end
    self.LocalizationDirectory = self._config.directory and Path:Combine(self._mod.path, self._config.directory) or self._mod.path

    self.Localizations = {}

    for _, tbl in ipairs(self._config) do
        if tbl._meta == "localization" or tbl._meta == "loc" then
            if not self.DefaultLocalization then
                self.DefaultLocalization = tbl.file
            end
            self.Localizations[Idstring(tbl.language):key()] = tbl.file
        end
    end

    self.DefaultLocalization = self._config.default or self.DefaultLocalization

    self:RegisterHooks()

    return true
end

function LocalizationModule:LoadLocalization()
    if self.Localizations[SystemInfo:language():key()] then
        LocalizationManager:load_localization_file(Path:Combine(self.LocalizationDirectory, self.Localizations[SystemInfo:language():key()]))
    else
        LocalizationManager:load_localization_file(Path:Combine(self.LocalizationDirectory, self.DefaultLocalization))
    end
end

function LocalizationModule:RegisterHooks()
    if managers.localization then
        self:LoadLocalization()
    else
        Hooks:Add("LocalizationManagerPostInit", self._mod.name .. "_Localization", function(loc)
            self:LoadLocalization()
    	end)
    end
end

BLT:RegisterModule(LocalizationModule.type_name, LocalizationModule)