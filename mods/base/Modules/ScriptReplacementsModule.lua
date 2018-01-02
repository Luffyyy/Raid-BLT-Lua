ScriptReplacementsModule = ScriptReplacementsModule or class(ModuleBase)
ScriptReplacementsModule.type_name = "ScriptMods"

function ScriptReplacementsModule:init(core_mod, config)
    if not ScriptReplacementsModule.super.init(self, core_mod, config) then
        return false
    end

    self.ScriptDirectory = self._config.directory and Path:Combine(self._mod.path, self._config.directory) or self._mod.path

    return true
end

function ScriptReplacementsModule:post_init()
    for _, tbl in ipairs(self._config) do
        if tbl._meta == "mod" then
            local options = tbl.options
            if options and options.use_clbk then
                options.use_clbk = self._mod:StringToCallback(options.use_clbk)
            end
            options = options or {}
            table.merge(options, {type = tbl.type or tbl.replacement_type, mode = options.merge_mode})
            local replacement = Path:Combine(self.ScriptDirectory, tbl.file or tbl.replacement)
            
            BLT.FileManager:ScriptReplaceFile(tbl.target_type or tbl.target_ext, tbl.target_file or tbl.target_path, replacement, options)
        end
    end
end

BLT:RegisterModule(ScriptReplacementsModule.type_name, ScriptReplacementsModule)