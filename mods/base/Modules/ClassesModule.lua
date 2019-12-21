ClassesModule = ClassesModule or class(ModuleBase)

ClassesModule.type_name = "Classes"

function ClassesModule:post_init(...)
    if not ClassesModule.super.post_init(self, ...) then
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
            BLT:RunHookFile(nil, {mod=self._mod,script=class_file})
        end
    end
end

function ClassesModule:GetPath()
    return Path:Combine(self._mod:GetPath(), self._config.directory)
end

function ClassesModule:GetInfo(append)
    append("Classes:")
    local path = self:GetPath()
    for _, c in pairs(self._config) do
        append("", Path:Combine(path, c.file))
    end
end

BLT:RegisterModule(ClassesModule.type_name, ClassesModule)