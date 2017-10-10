
CloneClass( MenuManager )
CloneClass( MenuCallbackHandler )
CloneClass( MenuModInfoGui )

Hooks:RegisterHook( "MenuManagerInitialize" )
Hooks:RegisterHook( "MenuManagerPostInitialize" )
function MenuManager:init( ... )
	self.orig.init( self, ... )
	Hooks:Call( "MenuManagerInitialize", self )
	Hooks:Call( "MenuManagerPostInitialize", self )
end

Hooks:RegisterHook( "MenuManagerOnOpenMenu" )
function MenuManager:open_menu( ... )
	self.orig.open_menu( self, ... )
	Hooks:Call( "MenuManagerOnOpenMenu", self, ...)
end

function MenuManager:show_download_progress( mod_name )

	local dialog_data = {}
	dialog_data.title = managers.localization:text("base_mod_download_downloading_mod", { ["mod_name"] = mod_name })
	dialog_data.mod_name = mod_name or "No Mod Name"

	local ok_button = {}
	ok_button.cancel_button = true
	ok_button.text = managers.localization:text("dialog_ok")

	dialog_data.focus_button = 1
	dialog_data.button_list = {
		ok_button
	}

	managers.system_menu:show_download_progress( dialog_data )

end

-- Create this function if it doesn't exist
function MenuCallbackHandler.can_toggle_chat( self )
	if managers and managers.menu then
		local input = managers.menu:active_menu() and managers.menu:active_menu().input
		return not input or input.can_toggle_chat and input:can_toggle_chat()
	else
		return true
	end
end

--------------------------------------------------------------------------------
-- Add BLT save function

function MenuCallbackHandler:perform_blt_save()
	BLT.Mods:Save()
end

function MenuCallbackHandler:close_blt_download_manager()
	managers.menu_component:close_blt_downloads_gui()
end

--------------------------------------------------------------------------------
-- Add BLT dll update notification

function MenuCallbackHandler:blt_update_dll_dialog()
	
	local dialog_data = {}
	dialog_data.title = managers.localization:text( "blt_update_dll_title" )
	dialog_data.text = managers.localization:text( "blt_update_dll_text" )

	local download_button = {}
	download_button.text = managers.localization:text( "blt_update_dll_goto_website" )
	download_button.callback_func = callback( self, self, "clbk_goto_paydaymods_download" )

	local ok_button = {}
	ok_button.text = managers.localization:text( "blt_update_later" )
	ok_button.cancel_button = true

	dialog_data.button_list = { download_button, ok_button }
	managers.system_menu:show( dialog_data )

end

function MenuCallbackHandler:clbk_goto_paydaymods_download()
	os.execute( "cmd /c start http://paydaymods.com/download/" )
end

--------------------------------------------------------------------------------
-- Add visibility callback for showing keybinds

function MenuCallbackHandler:blt_show_keybinds_item()
	return BLT.Keybinds and BLT.Keybinds:has_menu_keybinds()
end

-------------------------------------------------------------------------------- 
-- Menu Initiator for the Mod Options so that localization shows the selected language 
 
BLTModOptionsInitiator = BLTModOptionsInitiator or class( MenuInitiatorBase ) 
function BLTModOptionsInitiator:modify_node( node ) 
 
  local localization_item = node:item( "blt_localization_choose" ) 
  if localization_item and BLT.Localization then 
    localization_item:set_value( tostring(BLT.Localization:get_language().language) ) 
  end 
 
  return node 
 
end 
 
core:import("CoreMenuData")
core:import("CoreMenuLogic")
core:import("CoreMenuInput")
core:import("CoreMenuRenderer")
function MenuManager:register_menu_new(menu)
	if menu.name and self._registered_menus[menu.name] then
		return
	end

	menu.data = CoreMenuData.Data:new()
	menu.data:_load_data(menu.config, menu.id or menu.name)
	menu.data:set_callback_handler(menu.callback_handler)
	
	menu.logic = CoreMenuLogic.Logic:new( menu.data )
	menu.logic:register_callback("menu_manager_menu_closed", callback( self, self, "_menu_closed", menu.name))
	menu.logic:register_callback("menu_manager_select_node", callback( self, self, "_node_selected", menu.name))
	
	-- Input
	if not menu.input then
		menu.input = CoreMenuInput.MenuInput:new( menu.logic, menu.name )
	else
		menu.input = loadstring( "return " .. menu.input )()
		menu.input = menu.input:new( menu.logic, menu.name )
	end
	
	-- Renderer
	if not menu.renderer then
		menu.renderer = CoreMenuRenderer.Renderer:new( menu.logic )
	else
		menu.renderer = loadstring( "return " .. menu.renderer )()
		menu.renderer = menu.renderer:new( menu.logic )
	end
	menu.renderer:preload()
	
	if menu.name then
		self._registered_menus[ menu.name ] = menu
	else
		Application:error( "Manager:register_menu(): Menu '" .. menu.id .. "' is missing a name, in '" .. menu.content_file .. "'" )
	end
end