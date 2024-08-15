UpdatesModule = UpdatesModule or class(ModuleBase)
UpdatesModule.type_name = "AutoUpdates"
UpdatesModule._default_version_file = "version.txt"
UpdatesModule._always_enabled = true
UpdatesModule._can_have_multiple = true

UpdatesModule._providers = {
    modworkshop = {
        check_url = "https://api.modworkshop.net/mods/$id$/version",
        download_url = "https://api.modworkshop.net/mods/$id$/download",
        page_url = "https://modworkshop.net/mod/$id$",
        changelog_url = "https://modworkshop.net/mod/$id$?tab=changelog",
        check_condition = function(self)
            local id = tonumber(self.id)
            return id and id > 0
        end,
        check_func = function(self, data)
            if self:CompareVersions(self.version, data) == 2 then
                return data, nil -- update required, no error_reason
            end
            return false, nil    -- update not required, no error_reason
        end,
    },
}

-- returns 1 if version 1 is newer, 2 if version 2 is newer, or 0 if versions are equal.
function UpdatesModule:CompareVersions(version1, version2)
    local v1 = self:ToVersionTable(tostring(version1))
    local v2 = self:ToVersionTable(tostring(version2))
    for i = 1, math.max(#v1, #v2) do
        local num1 = v1[i] or 0
        local num2 = v2[i] or 0
        if num1 > num2 then
            return 1
        elseif num1 < num2 then
            return 2
        end
    end
    return 0
end

function UpdatesModule:ToVersionTable(version)
    local vt = {}
    for num in version:gmatch("%d+") do
        table.insert(vt, tonumber(num))
    end
    return vt
end

function UpdatesModule:init(core_mod, config)
    if not UpdatesModule.super.init(self, core_mod, config) then
        return false
    end

    self.steamid = Steam:userid()
    self.id = self._config.id
    self.display_name = self._config.display_name or self._mod.name
    self.version_func = self._config.version_func or false
    self.disallow_update = self._config.disallow_update or false
    self.update_url = self._config.update_url or false

    if self._config.provider then
        if self._providers[self._config.provider] then
            self.provider = self._providers[self._config.provider]
        else
            self:LogF(LogLevel.ERROR, "Setup", "No provider information for provider '%s'.", self._config.provider)
            return
        end
        -- elseif self._config.custom_provider then
        --     local provider_details = self._config.custom_provider
        --     if provider_details.check_func then provider_details.check_func = self._mod:StringToCallback(
        --         provider_details.check_func, self) end
        --     if provider_details.download_file_func then provider_details.download_file_func = self._mod:StringToCallback(
        --         provider_details.download_file_func, self) end
        --     self.provider = provider_details
    else
        self:Log(LogLevel.ERROR, "Setup", "No provider can be found for mod assets.")
        return
    end

    self.use_local_dir = NotNil(self._config.use_local_dir, true)
    self.use_local_path = NotNil(self._config.use_local_path, true)

    self.folder_names = self.use_local_dir and { table.remove(string.split(self._mod.path, "/")) } or
        (type(self._config.folder_name) == "string" and { self._config.folder_name } or Utils:RemoveNonNumberIndexes(self._config.folder_name))
    self.install_directory = (self._config.install_directory and self._mod:GetRealFilePath(self._config.install_directory, self)) or
        (self.use_local_path ~= false and Utils.Path:GetDirectory(self._mod.path)) or
        BLTModManager.Constants.mods_directory
    self.version_file = self._config.version_file and self._mod:GetRealFilePath(self._config.version_file, self) or
        Utils.Path:Combine(self.install_directory, self.folder_names[1], self._default_version_file)

    self._zip_name = self._mod.name .. self._name
    if self._mod._auto_updates[self.id] then
        self:Log(LogLevel.ERROR, "Setup", "Update id " .. self.id .. " already exists.")
        return
    end
    self._mod._auto_updates[self.id] = self
    if not self._mod._main_update then
        self._mod._main_update = self
    end

    self:RetrieveCurrentVersion()

    BLT.Updates:RegisterAutoUpdate(self)

    return true
end

function UpdatesModule:GetMainInstallDir()
    return Utils.Path:GetDirectory(self.version_file)
end

function UpdatesModule:RetrieveCurrentVersion()
    if FileIO:Exists(self.version_file) then
        local version = io.open(self.version_file):read("*all")
        if version then
            self.version = version
        end
    elseif self.version_func ~= false then
        self.version = BLTUpdateCallbacks[self.version_func](BLTUpdateCallbacks, self)
    elseif self._config.version then
        self.version = self._config.version
    end
    if tonumber(self.version) then -- has to be here, xml seems to fuckup numbers.
        self.version = math.round_with_precision(tonumber(self.version), 4)
    end
end

function UpdatesModule:CheckForUpdates(clbk)
    if self.provider.check_condition and not self.provider.check_condition(self) then
        return
    end

    self._requesting_updates = true

    if self.provider.check_func then
        dohttpreq(self._mod:GetRealFilePath(self.provider.check_url, self), function(data, id)
            local self = self

            if data and string.len(data) > 0 then
                local newer = self:CompareVersions(self.version, data)
                self:LogF(LogLevel.DEBUG, "CheckForUpdates", "Received version '%s' from the server (local is '%s'). %s",
                    data, tostring(self.version),
                    newer == 2 and "Update available!" or (newer == 1 and "[local is newer]" or "")
                )
                local requires_update, error_reason = self.provider.check_func(self, data)
                if requires_update ~= false and not error_reason then
                    self._new_version = requires_update
                end
                return self:_run_update_callback(clbk, requires_update, error_reason)
            else
                self._error = string.format("Unable to parse string '%s' as a version number.", data)
                self:Log(LogLevel.ERROR, "CheckForUpdates", self._error)
                return self:_run_update_callback(clbk, false, self._error)
            end
        end)
    else
        self._error = string.format("Unable to find check_func for update with id '%s'.", tostring(self.id))
        self:Log(LogLevel.ERROR, "CheckForUpdates", self._error)
        return self:_run_update_callback(clbk, false, self._error)
    end
end

-- function UpdatesModule:_CheckVersion(clbk)
--     local version_url = self._mod:GetRealFilePath(self.provider.version_api_url, self)
--     local loc = managers.localization
--     dohttpreq(version_url, function(data, id)
--         local self = self

--         self:LogF(LogLevel.INFO, "CheckVersion", "Received version '%s' from the server (local is '%s').", data,
--             tostring(self.version))
--         if data then
--             self._new_version = data
--             if self._new_version and self._new_version > self.version then
--                 self:PrepareForUpdate(clbk)
--             end
--         else
--             self:LogF(LogLevel.ERROR, "CheckVersion", "Unable to parse string '%s' as a version number.", data)
--         end
--     end)
-- end

-- function UpdatesModule:PrepareForUpdate(clbk)
--     BLT.Updates:AddAvailableUpdate(self)
--     if self._config.important and BLT.Options:GetValue("ImportantNotice") then
--         local loc = managers.localization
--         QuickMenu:new(loc:text("blt_mods_manager_important_title", { mod = self._mod.name }),
--             loc:text("blt_mods_manager_important_help"), { {
--             text = loc:text("dialog_yes"),
--             callback = function()
--                 BLT.UpdatesMenu:SetEnabled(true)
--             end
--         }, { text = loc:text("dialog_no"), is_cancel_button = true } })
--     end
-- end

function UpdatesModule:_run_update_callback(clbk, requires_update, error_reason)
    --self._requires_update = requires_update
    self._requesting_updates = false
    clbk(self, requires_update, error_reason)
    return requires_update
end

function UpdatesModule:IsCheckingForUpdates()
    return self._requesting_updates or false
end

function UpdatesModule:DownloadAssets()
    -- Check if this update is allowed to be updated by the update manager
    if self:DisallowsUpdate() then
        BLTUpdateCallbacks[self:GetDisallowCallback()](BLTUpdateCallbacks, self)
        return false
    end
    if self.provider.download_file_func then
        return self.provider.download_file_func(self)
    else
        return self:_DownloadAssets()
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
    BLT:OpenUrl(self._mod:GetRealFilePath(self.provider.page_url, self))
end

function UpdatesModule:ViewModChangelog()
    BLT:OpenUrl(self._mod:GetRealFilePath(self.provider.changelog_url, self))
end

function UpdatesModule:_DownloadAssets(data)
    local download_url = self._mod:GetRealFilePath(self.provider.download_url, data or self)
    self:LogF(LogLevel.DEBUG, "DownloadAssets", "Downloading assets from url '%s'.", download_url)
    return dohttpreq(download_url, callback(self, self, "StoreDownloadedAssets", false),
        callback(self, self, "SetUpdateProgress"))
end

function UpdatesModule:SetUpdateProgress(_httpreq_id, bytes, total_bytes)
    BLT.UpdatesMenu:SetUpdateProgress(self, bytes, total_bytes)
end

function UpdatesModule:StoreDownloadedAssets(config, data, id) -- FIXME: decouple from UI
    config = config or self._config
    local updates_menu = BLT.UpdatesMenu
    local coroutine = updates_menu._menu._ws:panel():panel({})
    coroutine:animate(function()
        wait(0.001)
        if config.install then
            config.install()
        else
            updates_menu:SetInstallingUpdate(self)
        end
        wait(1)

        self:Log(LogLevel.INFO, "DownloadAssets", "Finished downloading assets.")

        if string.is_nil_or_empty(data) then
            self:Log(LogLevel.ERROR, "DownloadAssets", "Assets download failed, received data was invalid.")
            if config.failed then
                config.failed()
            else
                updates_menu:SetFailedUpdate(self)
            end
            return
        end

        local temp_zip_path = self._zip_name .. ".zip"

        local file = io.open(temp_zip_path, "w+b")
        if file then
            file:write(data)
            file:close()
        else
            self:Log(LogLevel.ERROR, "DownloadAssets",
                "An error occured while trying to store the downloaded asset data.")
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
            updates_menu:SetUpdateDone(self)
            BLT.Updates:RemoveAvailableUpdate(self)
        end
        if alive(coroutine) then
            coroutine:parent():remove(coroutine)
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

function UpdatesModule:DisallowsUpdate()
    return self.disallow_update ~= false
end

function UpdatesModule:GetDisallowCallback()
    return self.disallow_update
end

BLT:RegisterModule(UpdatesModule.type_name, UpdatesModule)
