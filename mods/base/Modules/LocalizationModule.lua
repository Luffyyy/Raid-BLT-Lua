LocalizationModule = LocalizationModule or class(ModuleBase)

--Need a better name for this
LocalizationModule.type_name = "Localization"

function LocalizationModule:init(core_mod, config)
    if not LocalizationModule.super.init(self, core_mod, config) then
        return false
    end
    self.LocalizationDirectory = self._config.directory and Path:Combine(self._mod.path, self._config.directory) or
    self._mod.path

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
    local current_language = Idstring(Steam:current_language()):key()
    if self.Localizations[current_language] then
        LocalizationManager:load_localization_file(Path:Combine(self.LocalizationDirectory,
            self.Localizations[current_language]))
    end
    LocalizationManager:load_localization_file(Path:Combine(self.LocalizationDirectory, self.DefaultLocalization), false)
end

function LocalizationModule:RegisterHooks()
    if managers and managers.localization then
        self:LoadLocalization()
    else
        Hooks:Add("LocalizationManagerPostInit", self._mod.name .. "_Localization", function(loc)
            self:LoadLocalization()
        end)
    end
end

function LocalizationModule:GetInfo(append)
    append("Localization:")
    append("", "Default language:", tostring(self.DefaultLocalization))
    append("", "Languages:")
    for _, tbl in ipairs(self._config) do
        if tbl._meta == "localization" or tbl._meta == "loc" then
            append("", "", tostring(tbl.language), ">", tostring(tbl.file))
        end
    end
end

BLT:RegisterModule(LocalizationModule.type_name, LocalizationModule)
