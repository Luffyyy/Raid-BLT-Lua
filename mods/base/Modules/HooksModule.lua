HooksModule = HooksModule or class(ModuleBase)
HooksModule.type_name = "Hooks"

function HooksModule:post_init(...)
    if not HooksModule.super.post_init(self, ...) then
        return false
    end

    self:Load()

    return true
end

function HooksModule:Load()
    local path = self:GetPath()
    local registered_mod_hooks = self._mod.registered_hooks
    for _, hook in ipairs(self._config) do
        if hook._meta == "hook" then
            local source_file = hook.source_file or hook.hook_id
            local script = hook.file or hook.script_path
            BLT.Mods:RegisterHook(source_file, path, script, hook.type, self._mod)
            if source_file == "*" then
                table.insert(registered_mod_hooks.wildcards, script)
            elseif hook.type == "pre" then
                table.insert(registered_mod_hooks.pre, { source_file, script })
            else
                table.insert(registered_mod_hooks.post, { source_file, script })
            end
        end
    end
end

function HooksModule:GetPath()
    return Path:Combine(self._mod:GetPath(), self._config.directory)
end

BLT:RegisterModule(HooksModule.type_name, HooksModule)
