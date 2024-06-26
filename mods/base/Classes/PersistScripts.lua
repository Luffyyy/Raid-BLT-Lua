BLTPersistScripts = BLTPersistScripts or class()
--I'll be keeping this for old format, you should use the classes module for new format(or hooks for more specific execution time)
function BLTPersistScripts:init()
	Hooks:Add("MenuUpdate", "BLTPersistScripts.MenuUpdate", function(t, dt)
		self:update_persists()
	end)
	Hooks:Add("GameSetupUpdate", "BLTPersistScripts.GameSetupUpdate", function(t, dt)
		self:update_persists()
	end)
end

function BLTPersistScripts:update_persists()
	-- Iterate through all mods and their persist scripts
	for _, mod in ipairs(BLT.Mods:Mods()) do
		for _, persist in ipairs(mod:GetPersistScripts()) do
			-- Check if the persist global has not been set
			if not rawget(_G, persist.global) then
				-- Create the path here, otherwise Application.nice_path doesn't exist yet
				if not persist.path then
					persist.path = Application:nice_path(mod:GetPath() .. "/" .. persist.file, false)
				end
				-- Set the PersistScriptPath for legacy support
				rawset(_G, "PersistScriptPath", persist.path)
				-- Run the persist script file
				dofile(persist.path)
			end
		end
	end

	-- Unset the PersistScriptPath for legacy purposes
	rawset(_G, "PersistScriptPath", nil)
end
