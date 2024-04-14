CloneClass(MenuManager)
CloneClass(MenuCallbackHandler)
CloneClass(MenuModInfoGui)

Hooks:RegisterHook("MenuManagerInitialize")
Hooks:RegisterHook("MenuManagerPostInitialize")
function MenuManager:init(...)
	self.orig.init(self, ...)
	Hooks:Call("MenuManagerInitialize", self)
	Hooks:Call("MenuManagerPostInitialize", self)
end

Hooks:RegisterHook("MenuManagerOnOpenMenu")
function MenuManager:open_menu(...)
	self.orig.open_menu(self, ...)
	Hooks:Call("MenuManagerOnOpenMenu", self, ...)
end

-- Create this function if it doesn't exist
function MenuCallbackHandler:can_toggle_chat()
	if managers and managers.menu then
		local input = managers.menu:active_menu() and managers.menu:active_menu().input
		return not input or input.can_toggle_chat and input:can_toggle_chat()
	else
		return true
	end
end

function MenuManager:toggle_menu_state(...)
	if BLT.Dialogs:DialogOpened() then
		BLT.Dialogs:CloseLastDialog()
		if managers.menu:active_menu() and managers.menu:active_menu().renderer then
			managers.menu:active_menu().renderer:disable_input(0.2)
		end
		return
	else
		return self.orig.toggle_menu_state(self, ...)
	end
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

	menu.logic = CoreMenuLogic.Logic:new(menu.data)
	menu.logic:register_callback("menu_manager_menu_closed", callback(self, self, "_menu_closed", menu.name))
	menu.logic:register_callback("menu_manager_select_node", callback(self, self, "_node_selected", menu.name))

	-- Input
	if not menu.input then
		menu.input = CoreMenuInput.MenuInput:new(menu.logic, menu.name)
	else
		menu.input = loadstring("return " .. menu.input)()
		menu.input = menu.input:new(menu.logic, menu.name)
	end

	-- Renderer
	if not menu.renderer then
		menu.renderer = CoreMenuRenderer.Renderer:new(menu.logic)
	else
		menu.renderer = loadstring("return " .. menu.renderer)()
		menu.renderer = menu.renderer:new(menu.logic)
	end
	menu.renderer:preload()

	if menu.name then
		self._registered_menus[menu.name] = menu
	else
		Application:error("Manager:register_menu(): Menu '" ..
		menu.id .. "' is missing a name, in '" .. menu.content_file .. "'")
	end
end
