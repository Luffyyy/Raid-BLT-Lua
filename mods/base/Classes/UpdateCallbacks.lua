-- BLT Update Callbacks
-- If you want to only conditionally enable updates for your mod, define
--   a function onto this table and add a present_func tag to your update block
BLTUpdateCallbacks = {}

function BLTUpdateCallbacks:blt_dll_version()
	return blt.GetDllVersion and blt.GetDllVersion() or "0.0.0.0"
end

function BLTUpdateCallbacks:blt_update_dll_dialog(update)
	local update_url = update.update_url

	QuickMenu:new(
		managers.localization:text("blt_update_dll_title"),
		managers.localization:text("blt_update_dll_text"),
		{
			[0] = {
				text = managers.localization:text("blt_update_dll_goto_website"),
				callback = function()
					BLT:OpenUrl(update_url)
				end
			},
			[1] = {
				text = managers.localization:text("blt_update_later"),
				is_cancel_button = true
			}
		},
		true
	)
end
