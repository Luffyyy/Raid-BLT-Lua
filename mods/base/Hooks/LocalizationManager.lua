
LocalizationManager._custom_localizations = LocalizationManager._custom_localizations or {}
Hooks:RegisterHook("LocalizationManagerPostInit")
Hooks:Post(LocalizationManager, "init", "BLT.LocalizationManager.Init", function(self, ...)
	Hooks:Call("LocalizationManagerPostInit", self, ...)
end)

LocalizationManager._orig_text = LocalizationManager._orig_text or LocalizationManager.text
function LocalizationManager:text(str, macros, ...)
	if self._custom_localizations[str] then
		local return_str = self._custom_localizations[str]
		if macros and type(macros) == "table" then
			for k, v in pairs(macros) do
				return_str = return_str:gsub("$" .. k, v)
			end
		end
		return return_str
	end
	return self:_orig_text(str, macros, ...)
end

function LocalizationManager:add_localized_strings(string_table, overwrite)
	-- Should we overwrite existing localization strings
	if overwrite == nil then
		overwrite = true
	end

	if type(string_table) == "table" then
		for k, v in pairs(string_table) do
			if not self._custom_localizations[k] or (self._custom_localizations[k] and overwrite) then
				self._custom_localizations[k] = v
			end
		end
	end
end

function LocalizationManager:load_localization_file(file_path, overwrite)
	-- Should we overwrite existing localization strings
	if overwrite == nil then
		overwrite = true
	end

	local file = io.open(file_path, "r")
	if file then
		local file_contents = file:read("*all")
		file:close()

		local contents = json.decode(file_contents)
		self:add_localized_strings(contents, overwrite)
	end
end