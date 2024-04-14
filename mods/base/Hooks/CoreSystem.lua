local function overwrite_meta_function(tbl, func_name, new_func)
	local old_func_name = "_" .. func_name
	local meta_table = getmetatable(tbl)

	if not meta_table[func_name] then
		BLT:LogF(LogLevel.ERROR, "BLTFileManager", "Function with name '%s' could not be found in the meta table!",
			func_name)
		return
	end

	meta_table[old_func_name] = meta_table[old_func_name] or meta_table[func_name]
	meta_table[func_name] = new_func
end

overwrite_meta_function(PackageManager, "script_data", function(self, ext, path, name_mt)
	return BLT.FileManager:Process(ext, path, name_mt)
end)

overwrite_meta_function(PackageManager, "has", function(self, ext, path)
	if BLT.FileManager:Has(ext, path) or BLT.FileManager:HasScriptMod(ext, path) then
		return true
	end

	return self:_has(ext, path)
end)

overwrite_meta_function(DB, "has", function(self, ext, path)
	if BLT.FileManager:HasScriptMod(ext, path) then
		return true
	end

	return self:_has(ext, path)
end)
