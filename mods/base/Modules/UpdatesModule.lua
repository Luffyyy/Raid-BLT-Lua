UpdatesModule = UpdatesModule or class(ModuleBase)
UpdatesModule.type_name = "AutoUpdates"
UpdatesModule._default_version_file = "version.txt"
UpdatesModule._always_enabled = true

UpdatesModule._providers = {
    modworkshop = {
        check_url = "https://api.modwork.shop/api.php?command=CompareVersion&did=$id$&vid=$version$&steamid=$steamid$&token=Je3KeUETqqym6V8b5T7nFdudz74yWXgU",
        get_files_url = "https://api.modwork.shop/api.php?command=AssocFiles&did=$id$&steamid=$steamid$&token=Je3KeUETqqym6V8b5T7nFdudz74yWXgU",
        download_url = "https://api.modwork.shop/api.php?command=DownloadFile&fid=$fid$&steamid=$steamid$&token=Je3KeUETqqym6V8b5T7nFdudz74yWXgU",
        page_url = "https://modwork.shop/$id$",
        check_func = function(self)
            local id = tonumber(self.id)
            if not id or id <= 0 then
                return
            end
            --optimization, mostly you don't really need to check updates again when going back to menu
            local upd = Global.blt_checked_updates[self.id]
            if upd then
                if type(upd) == "string" and upd ~= tostring(self.version) then
                    self._new_version = upd
                    self:PrepareForUpdate()
                end
                return
            end
            dohttpreq(self._mod:GetRealFilePath(self.provider.check_url, self), function(data, id)
                if data then
                    data = string.sub(data, 0, #data - 1)
                    if data ~= "false" and data ~= "true" and string.len(data) > 0 then
                        self._new_version = data
                        Global.blt_checked_updates[self.id] = data
                        self:PrepareForUpdate()
                    else
                        Global.blt_checked_updates[self.id] = true
                    end
                end
            end)
        end,
        download_file_func = function(self)
            local get_files_url = self._mod:GetRealFilePath(self.provider.get_files_url, self)
            dohttpreq(get_files_url, function(data, id)
                local fid = string.split(data, '"')[1]
                if fid then
                    self:_DownloadAssets({fid = fid, steamid = self.steamid})
                    Global.blt_checked_updates[self.id] = nil --check again later for hotfixes.
                end    
            end)
        end
    },
    paydaymods = {
        check_url = "http://api.paydaymods.com/updates/retrieve/?mod[0]=$id$",
        download_url = "http://download.paydaymods.com/download/latest/$id$",
        get_hash = function(self)
        	if self._config.hash_file then
                return SystemFS:exists(self._config.hash_file) and file.FileHash(self._config.hash_file) or nil
            else
                local directory = Application:nice_path(self:GetMainInstallDir(), true)
                return SystemFS:exists(directory) and file.DirectoryHash(directory) or nil
            end
        end,
        check_func = function(self)
            dohttpreq(self._mod:GetRealFilePath(self.provider.check_url, self), function(json_data, http_id)
                local self = self
                self._requesting_updates = false
        
                if json_data:is_nil_or_empty() then
                    self:Log(LogLevel.WARN, "UpdateCheck", "Could not connect to the PaydayMods.com API!")
                    return
                end
        
                local server_data = json.decode(json_data)
                if server_data then
                    for _, data in pairs(server_data) do
                        self:LogF(LogLevel.INFO, "UpdateCheck", "Received update data for '%s'.", data.ident)
                        if data.ident == self.id then
                            self._server_hash = data.hash
                            local local_hash = self.provider.get_hash(self)
                            self:LogF(LogLevel.DEBUG, "UpdateCheck", "Comparing hash data:\nServer: '%s'\n Local: '%s'.", data.hash, local_hash)
                            if data.hash then
                                if data.hash ~= local_hash then
                                    self:PrepareForUpdate()
                                    return
                                end
                            end
                        end
                        return
                    end
                end
                self:LogF(LogLevel.WARN, "UpdateCheck", "Paydaymods did not return a result for id '%s'.", tostring(self.id))
            end)
        end
    }
}

function UpdatesModule:init(core_mod, config)
    if not UpdatesModule.super.init(self, core_mod, config) then
        return false
    end

    self.steamid = Steam:userid()
    self.id = self._config.id

    if self._config.provider then
        if self._providers[self._config.provider] then
            self.provider = self._providers[self._config.provider]
        else
            self:LogF(LogLevel.ERROR, "Setup", "No provider information for provider '%s'.", self._config.provider)
            return
        end
    elseif self._config.custom_provider then
        local provider_details = self._config.custom_provider
        if provider_details.check_func then provider_details.check_func = self._mod:StringToCallback(provider_details.check_func, self) end
        if provider_details.download_file_func then provider_details.download_file_func = self._mod:StringToCallback(provider_details.download_file_func, self) end
        self.provider = provider_details
    else
        self:Log(LogLevel.ERROR, "Setup", "No provider can be found for mod assets.")
        return
    end

    self.use_local_dir = NotNil(self._config.use_local_dir, true)
    self.use_local_path = NotNil(self._config.use_local_path, true)

    self.folder_names = self.use_local_dir and {table.remove(string.split(self._mod.path, "/"))} or (type(self._config.folder_name) == "string" and {self._config.folder_name} or Utils:RemoveNonNumberIndexes(self._config.folder_name))
    self.install_directory = (self._config.install_directory and self._mod:GetRealFilePath(self._config.install_directory, self)) or (self.use_local_path ~= false and Utils.Path:GetDirectory(self._mod.path)) or BLTModManager.Constants.mod_overrides_directory
    self.version_file = self._config.version_file and self._mod:GetRealFilePath(self._config.version_file, self) or Utils.Path:Combine(self.install_directory, self.folder_names[1], self._default_version_file)

    self._update_manager_id = self._mod.name .. self._name
    self._mod.update_key = (self._config.is_standalone ~= false) and self.id
    self._mod.auto_updates_module = self
    self:RetrieveCurrentVersion()

    -- if not self._config.manual_check then
    --     self:RegisterAutoUpdateCheckHook()
    -- end

    return true
end

function UpdatesModule:GetMainInstallDir()
    return Utils.Path:GetDirectory(self.version_file)
end

function UpdatesModule:RegisterAutoUpdateCheckHook()
    local hook_id = self._mod.name .. self._name .. "UpdateCheck"
    Hooks:Add("MenuManagerOnOpenMenu", hook_id, function(self_menu, menu, index)
        if menu == "menu_main" and not LuaNetworking:IsMultiplayer() then
            self:CheckVersion()
            Hooks:RemoveHook("MenuManagerOnOpenMenu", hook_id) 
        end
    end)
end

function UpdatesModule:RetrieveCurrentVersion()
    if FileIO:Exists(self.version_file) then
        local version = io.open(self.version_file):read("*all")
        if version then
            self.version = version
        end
    elseif self._config.version then
        self.version = self._config.version
    end
    if tonumber(self.version) then -- has to be here, xml seems to fuckup numbers.
        self.version = math.round_with_precision(tonumber(self.version), 4)
    end
end

function UpdatesModule:CheckVersion(force)
    if self.provider.check_func then
        self.provider.check_func(self, force)
    else
        self:_CheckVersion(force)
    end
end

function UpdatesModule:PrepareForUpdate()
    BLT.ModsMenu:SetModNeedsUpdate(self._mod, self._new_version)
    if self._config.important and BLT.Options:GetValue("ImportantNotice") then
        local loc = managers.localization
        QuickMenu:new(loc:text("blt_mods_manager_important_title", {mod = self._mod.name}), loc:text("blt_mods_manager_important_help"), {{text = loc:text("dialog_yes"), callback = function()
            BLT.ModsMenu:SetEnabled(true)
        end}, {text = loc:text("dialog_no"), is_cancel_button = true}})
    end
end

function UpdatesModule:_CheckVersion(force)
    local version_url = self._mod:GetRealFilePath(self.provider.version_api_url, self)
    local loc = managers.localization
    dohttpreq(version_url, function(data, id)
        local self = self
        self:LogF(LogLevel.INFO, "CheckVersion", "Received version '%s' from the server (local is '%s').", data, tostring(self.version))
        if data then
            self._new_version = data
            if self._new_version and self._new_version ~= self.version then
                self:PrepareForUpdate()
            elseif force then
                self:ShowNoChangePrompt()
            end
        else
            self:LogF(LogLevel.ERROR, "CheckVersion", "Unable to parse string '%s' as a version number.", data)
        end
    end)
end

function UpdatesModule:ShowNoChangePrompt()
    QuickMenu:new(
        managers.localization:text("blt_no_change"),
        managers.localization:text("blt_no_change_desc"),
        {{
            text = managers.localization:text("menu_ok"),
            is_cancel_button = true
        }},
        true
    )
end

function UpdatesModule:DownloadAssets()
    if self.provider.download_file_func then
        self.provider.download_file_func(self)
    else
        self:_DownloadAssets()
    end
end

function UpdatesModule:HasPage()
    if self.provider.has_page then
        return self.provider.has_page(self)
    else
        return self.provider.page_url ~= nil
    end
end
 
function UpdatesModule:ViewMod()
    local url = self._mod:GetRealFilePath(self.provider.page_url, self)
    if Steam:overlay_enabled() then
		Steam:overlay_activate("url", url)
	else
		os.execute("cmd /c start " .. url)
	end
end

function UpdatesModule:_DownloadAssets(data)
    local download_url = self._mod:GetRealFilePath(self.provider.download_url, data or self)
    self:LogF(LogLevel.INFO, "Downloading assets from url '%s'.", download_url)
    local mods_menu = BLT.ModsMenu
    dohttpreq(download_url, callback(self, self, "StoreDownloadedAssets", false), callback(mods_menu, mods_menu, "SetModProgress", self._mod))                
end

function UpdatesModule:StoreDownloadedAssets(config, data, id)
    config = config or self._config
    local mods_menu = BLT.ModsMenu
    local coroutine = mods_menu._menu._ws:panel():panel({})
    coroutine:animate(function()
        wait(0.001)
        if config.install then
            config.install()
        else
            mods_menu:SetModInstallingUpdate(self._mod)
        end
        wait(1)
        
        self:Log(LogLevel.INFO, "DownloadAssets", "Finished downloading assets.")

        if string.is_nil_or_empty(data) then
            self:Log(LogLevel.ERROR, "DownloadAssets", "Assets download failed, received data was invalid.")
            if config.failed then
                config.failed()
            else
                mods_menu:SetModFailedUpdate(self._mod)
            end
            return
        end

        local temp_zip_path = self._update_manager_id .. ".zip"

        local file = io.open(temp_zip_path, "wb+")
        if file then
            file:write(data)
            file:close()
        else
            self:Log(LogLevel.ERROR, "DownloadAssets", "An error occured while trying to store the downloaded asset data.")
            return
        end
        
        if self._config and not self._config.dont_delete then
            for _, dir in pairs(self.folder_names) do
                local path = Utils.Path:Combine(self.install_directory, dir)
                if FileIO:Exists(path) then
                    FileIO:Delete(path)
                end
            end
        end
        unzip(temp_zip_path, config.install_directory or self.install_directory)
        FileIO:Delete(temp_zip_path)

        if config.done_callback then
            config.done_callback()
        end
        self.version = self._new_version        
        if config.finish then
            config.finish()
        else
            mods_menu:SetModNormal(self._mod)
        end
        if alive(coroutine) then
            coroutine:parnet():remove(coroutine)
        end
    end)
end

function UpdatesModule:GetInfo(append)
    append("Auto-updates:")
    if self.provider and self.provider.get_info then
        self.provider.get_info(self, append)
    else
        if self._config.provider then
            append("", "Provider:", tostring(self._config.provider))
        else
            append("", "No Provider")
        end
        if self.id then
            append("", "Id:", tostring(self.id))
        end
        if self.version then
            append("", "Version:", tostring(self.version))
        end
    end
end

BLT:RegisterModule(UpdatesModule.type_name, UpdatesModule)