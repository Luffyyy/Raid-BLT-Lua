HooksModule = HooksModule or class(ModuleBase)
HooksModule.type_name = "hooks"

function HooksModule:init(core_mod, config)
    if not HooksModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()

    return true
end

function HooksModule:Load()
    local path = self:GetPath()
    for _, hook in ipairs(self._config) do
        if hook._meta == "hook" then
            local source_file = hook.source_file or hook.hook_id
            local script = hook.file or hook.script_path
            BLT.Mods:RegisterHook(source_file, path, script, hook.type, self._mod)
            if source_file == "*" then
                table.insert(self._mod.registered_hooks.wildcards, script)
            elseif hook.type == "pre" then
                table.insert(self._mod.registered_hooks.pre, {source_file, script})
            else
                table.insert(self._mod.registered_hooks.post, {source_file, script})
            end
        end
    end
end

function HooksModule:GetPath()
    return Path:Combine(self._mod.path, self._config.directory)
end

BLT:RegisterModule(HooksModule.type_name, HooksModule)