
LocalizationManager._custom_localizations = LocalizationManager._custom_localizations or {}
Hooks:RegisterHook("LocalizationManagerPostInit")
Hooks:Post(LocalizationManager, "init", "BLT.LocalizationManager.Init", function(self, ...)
	Hooks:Call("LocalizationManagerPostInit", self, ...)
end)

LocalizationManager._orig_text = LocalizationManager._orig_text or LocalizationManager.text
function LocalizationManager:text(str, macros, ...)
	if self._custom_localizations[str] then
		local return_str = self._custom_localizations[str]

		-- Look for macros in the old BLT format without a trailing ;
		if type(macros) == "table" then
			local deprecated_use = false
			for k, v in pairs(macros) do
				local i, j = return_str:find("$" .. k)
				if i and return_str:byte(j + 1) ~= 59 then -- $X format, without ;
					return_str = return_str:gsub("$" .. k, v)
					deprecated_use = true
				end
			end
			if deprecated_use then
				log("[BLT] The use of macros without a trailing semicolon is deprecated in " .. tostring(str))
			end
		end

		-- Look for macros in the return string in the form of $X;
		for k in return_str:gmatch("%$([^;%s]+);") do
			local lookup = "$" .. k .. ";"
			local replacement = type(macros) == "table" and macros[k]
				or self._default_macros and self._default_macros[lookup]
			if replacement then
				return_str = return_str:gsub(lookup, replacement, 1, true)
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
			if overwrite or not self._custom_localizations[k] then
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