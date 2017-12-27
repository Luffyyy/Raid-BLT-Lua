ClassesModule = ClassesModule or class(ModuleBase)

ClassesModule.type_name = "classes"

function ClassesModule:init(core_mod, config)
    if not ClassesModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()
    return true
end

function ClassesModule:Load()
    local path = self:GetPath()
    for _, c in ipairs(self._config) do
        if type(c) == "table" and c._meta == "class" then
            local class_file = Path:Combine(path, c.file)
            if FileIO:Exists(class_file) then
                dofile(class_file)
            else
                BLT:log("[ERROR] Class file not readable by the lua state! File: %s", class_file)
            end
        end
    end
end

function ClassesModule:GetPath()
    return Path:Combine(self._mod.path, self._config.directory, "")
end

function ClassesModule:GetInfo(append)
    append("Classes:")
    local path = self:GetPath()
    for _, c in pairs(self._config) do
        append("", Path:Combine(path, c.file))
    end
end

BLT:RegisterModule(ClassesModule.type_name, ClassesModule)