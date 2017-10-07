BLTMenu = BLTMenu or blt_class(RaidGuiBase)
--In Raid menus would be made either with json or by inherting BLTMenu class and adding it to menu components by RaidMenuHelper:CreateMenu
--core functions
function BLTMenu:init(ws, fullscreen_ws, node)
    self._ws = ws
    self._fullscreen_ws = fullscreen_ws
    self._fullscreen_panel = self._fullscreen_ws:panel():panel({})
    self._panel = self._ws:panel():panel({})
    --do we need a name..? hard without a decomp :/
    BLTMenu.super.init(self, ws, fullscreen_ws, node, "")
    self:Init(self._root_panel)
end

function BLTMenu:close()
    self._ws:panel():remove(self._panel)
    self._fullscreen_ws:panel():remove(self._fullscreen_panel)
    self._root_panel:clear()
    self:Close()
end

--to be used by mod creators 

--And then just add items
--Root is like the holder of your menu you could say
function BLTMenu:Init(root)
end

function BLTMenu:Close()
end

function BLTMenu:Button(params)
    local parent = params.parent or self._root_panel
    if parent then
        local btn = parent:button({
            name = params.name,            
			background_color = params.background_color,
			alpha = params.alpha,
            w = 500,
			h = 50,
		})
		btn._callback_handler = self
		if params.text then
			btn:set_text(params.text)
		end
		return btn
    end
end

--Basically all the shit that was in mods_menu, view_mod and download_manager but instead of fucking repeating it.
BLTCustomMenu = BLTCustomMenu or blt_class(RaidGuiBase)
function BLTCustomMenu:init(ws, fullscreen_ws, node, name)
    self._ws = ws
    self._fullscreen_ws = fullscreen_ws
    self._fullscreen_panel = self._fullscreen_ws:panel():panel({})
    self._panel = self._ws:panel():panel({layer = 20})
    self._init_layer = self._ws:panel():layer()
    
    self._data = node:parameters().menu_component_data or {}
    self._buttons = {}
    self:_setup()
    BLTCustomMenu.super.init(self, ws, fullscreen_ws, node, name)
end

function BLTCustomMenu:close()
    self._ws:panel():remove(self._panel)
    self._fullscreen_ws:panel():remove(self._fullscreen_panel)
    self._root_panel:clear()
end

function BLTCustomMenu:mouse_pressed( o, button, x, y )
	BLTCustomMenu.super.mouse_pressed(self, o, button, x, y)
	local result = false 
	
	for _, item in ipairs( self._buttons ) do 
	   if item:inside( x, y ) then 
		 if item.mouse_clicked then 
		   result = item:mouse_clicked( button, x, y ) 
		 end 
		 break 
	   end 
	end 
	
	if button == Idstring( "0" ) then 
	
		for _, item in ipairs( self._buttons ) do
			if item:inside( x, y ) then
				if item:parameters().callback then
					item:parameters().callback()
				end
				managers.menu_component:post_event( "menu_enter" )
				return true
			end
		end

    end
    
    if alive(self._scroll) then
        return self._scroll:mouse_pressed( o, button, x, y )
    end

	return result
	
end

function BLTCustomMenu:mouse_moved(o, x, y)
    if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
        return false
    end
    BLTCustomMenu.super.mouse_moved(self, o, x, y)

    local used, pointer

    local inside_scroll = alive(self._scroll) and self._scroll:panel():inside( x, y )
    for _, item in ipairs( self._buttons ) do
        if not used and item:inside( x, y ) and inside_scroll then
            item:set_highlight( true )
            used, pointer = true, "link"
        else
            item:set_highlight( false )
        end
    end

    if alive(self._scroll) and not used then
        used, pointer = self._scroll:mouse_moved( o, x, y )
    end

    return used, pointer
end
    
function BLTCustomMenu:mouse_clicked(o, button, x, y)
    if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
        return false
    end

    BLTCustomMenu.super.mouse_clicked(self, o, button, x, y)

    if alive(self._scroll) then
        return self._scroll:mouse_clicked( o, button, x, y )
    end
end

function BLTCustomMenu:mouse_released(o, button, x, y)
	if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
		return false
    end
    
    BLTCustomMenu.super.mouse_released(self, o, button, x, y)
	if alive(self._scroll) then
		return self._scroll:mouse_released( button, x, y )
	end
end

function BLTCustomMenu:mouse_wheel_up( x, y )
	if alive(self._scroll) then
		self._scroll:scroll( x, y, 1 )
	end
end

function BLTCustomMenu:mouse_wheel_down( x, y )
	if alive(self._scroll) then
		self._scroll:scroll( x, y, -1 )
	end
end

function BLTCustomMenu:make_fine_text(text)
    if not alive(text) then
        return
    end
	local x,y,w,h = text:text_rect()
	text:set_size(w, h)
	text:set_position(math.round(text:x()), math.round(text:y()))
end


RaidBackButton = RaidBackButton or blt_class(BLTCustomMenu)
function RaidBackButton:init(ws, fullscreen_ws, node)
    RaidGuiBase:set_legend({
        controller = {"menu_legened_back"},
        keyboard = {{key = "footer_back", callback = callback(managers.raid_menu, managers.raid_menu, "close_menu")}},
    })
end

-------------------------------------------------------------------------------
-- Adds a back button to a menu

Hooks:Add("MenuComponentManagerInitialize", "RaidBackButton.MenuComponentManagerInitialize", function(self)
	self._active_components.raid_back_button = {create = callback(self, self, "create_raid_back_button"), close = callback(self, self, "remove_raid_back_button")}
end)

function MenuComponentManager:remove_raid_back_button(node)
    --no need to lol
end

function MenuComponentManager:create_raid_back_button(node)
	if not node then
		return
    end
    RaidGuiBase:set_legend({
        controller = {"menu_legened_back"},
        keyboard = {{key = "footer_back", callback = RaidGuiBase._on_legend_pc_back}},
    })
end