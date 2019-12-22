
BLTLocalization = BLTLocalization or class()
BLTLocalization.default_language_code = "en"
BLTLocalization.directory = "mods/base/Loc/"
function BLTLocalization:init()
	-- Initialize module
	self._languages = {}
	self._current = "en"
end

function BLTLocalization:load_languages()
	-- Clear languages
	self._languages = {}

	-- Add all localisation files
	local loc_files = file.GetFiles(self.directory)
	for i, file_name in ipairs(loc_files) do
		local data = {
			file = Application:nice_path(self.directory .. file_name, false),
			language = string.gsub(file_name, ".txt", "")
		}
		table.insert(self._languages, data)
	end

	-- Sort languages alphabetically by code to ensure we always have the same order
	table.sort(self._languages, function(a, b)
		if a.language == self.default_language_code then return true end
		if b.language == self.default_language_code then return false end
		return a.language < b.language
	end)

	-- Load the language that was loaded from the BLT save if it is available
	self._languages_loaded = true
	if self._desired_language_on_load then
		self:set_language(self._desired_language_on_load)
		self._desired_language_on_load = nil
	end

end

function BLTLocalization:languages()
	return self._languages
end

function BLTLocalization:_get_language_from_code(lang_code)
	for idx, lang in ipairs(self._languages) do
		if lang.language == lang_code then
			return lang, idx
		end
	end
end

function BLTLocalization:get_language()
	return self:_get_language_from_code(self._current)
end

function BLTLocalization:set_language(lang_code)
	if not self._languages_loaded then
		self._desired_language_on_load = lang_code
		return false
	end

	local lang = self:_get_language_from_code(lang_code)
	if lang then
		self._current = lang.language
		BLT.Options:SetValue("Language", self._current)
		return true
	else
		return false
	end
end

function BLTLocalization:load_localization(loc_manager)
	local localization_manager = loc_manager or managers.localization
	if not localization_manager then
		BLT:Log(LogLevel.ERROR, "BLTLocalization", "Can not load localization without a valid localization manager!")
		return false
	end

	local default_lang = self:_get_language_from_code(self.default_language_code)
	if default_lang then
		localization_manager:load_localization_file(default_lang.file)
	else
		BLT:LogF(LogLevel.ERROR, "BLTLocalization", "Could not load localization file for language '%s'.", tostring(self.default_language_code))
	end

	local lang = self:get_language()
	if lang then
		if lang.language ~= self.default_language_code then
			localization_manager:load_localization_file(lang.file)
		end
	else
		BLT:LogF(LogLevel.ERROR, "BLTLocalization", "Could not load localization file for language '%s'.", tostring(self._current))
	end
end

--------------------------------------------------------------------------------
-- Save/Load

Hooks:Add("BLTOnLoadData", "BLTOnLoadData.BLTLocalization", function(cache)
	BLT.Localization:set_language(BLT.Options:GetValue("Language"))
end)

--------------------------------------------------------------------------------
-- Load languages once the game's localization manager has been created

Hooks:Add("LocalizationManagerPostInit", "BLTLocalization.LocalizationManagerPostInit", function(self)
	BLT.Localization:load_languages()
	BLT.Localization:load_localization(self)
end)