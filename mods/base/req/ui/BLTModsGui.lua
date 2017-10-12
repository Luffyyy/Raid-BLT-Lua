
BLT:Require("req/ui/BLTUIControls")
BLT:Require("req/ui/BLTModItem")
BLT:Require("req/ui/BLTViewModGui")

BLTModsGui = BLTModsGui or blt_class(BLTCustomMenu)
BLTModsGui.last_y_position = 0

local padding = 10

local large_font = tweak_data.menu.pd2_large_font
local large_font_size = tweak_data.menu.pd2_large_font_size
function BLTModsGui:init(ws, fullscreen_ws, node)
	BLTModsGui.super.init(self, ws, fullscreen_ws, node, "blt_mods")
end

function BLTModsGui:close()
	BLTModsGui.last_y_position = self._scroll:canvas():y() * -1 
	BLTModsGui.super.close(self)
end

function BLTModsGui:_setup()
	-- Title
	local title = self._panel:text({
		name = "title",
		x = padding,
		y = padding,
		font_size = large_font_size,
		font = large_font,
		h = large_font_size,
		layer = 10,
		--blend_mode = "add",
		color = tweak_data.gui.colors.raid_white,
		text = "Installed Mods",
		align = "left",
		vertical = "top",
	})

	-- Mods scroller
	local scroll_panel = self._panel:panel({
		h = self._panel:h() - large_font_size * 2 - padding * 2,
		y = large_font_size,
	})
	self._scroll = ScrollablePanel:new( scroll_panel, "mods_scroll", {} )

	-- Create download manager button
	local title_text = managers.localization:text("blt_download_manager")
	local downloads_count = table.size( BLT.Downloads:pending_downloads() )
	if downloads_count > 0 then
		title_text = title_text .. " (" .. tostring(downloads_count) .. ")"
	end

	local button = BLTUIButton:new(self._scroll:canvas(), {
		x = 0,
		y = 0,
		w = (self._scroll:canvas():w() - (BLTModItem.layout.x + 1) * padding) / BLTModItem.layout.x,
		h = 256,
		title = title_text,
		text = managers.localization:text("blt_download_manager_help"),
		color = tweak_data.gui.colors.raid_red,
		image = "ui/hud/atlas/raid_atlas",
		image_rect = {891, 1285, 64, 64},
		image_size = 96,
		color_image = true,
		callback = callback( self, self, "clbk_open_download_manager" )
	})
	table.insert( self._buttons, button )

	-- Create mod boxes
	for i, mod in ipairs( BLT.Mods:Mods() ) do
		local item = BLTModItem:new( self._scroll:canvas(), i + 1, mod )
		table.insert( self._buttons, item )
	end

	-- Update scroll size
	self._scroll:update_canvas_size()
	self._scroll:scroll_to(BLTModsGui.last_y_position) 
end

function BLTModsGui:inspecting_mod()
	return self._inspecting
end

function BLTModsGui:clbk_open_download_manager()
	managers.raid_menu:open_menu( "blt_download_manager" )
end

--------------------------------------------------------------------------------

function BLTModsGui:mouse_pressed( o, button, x, y )
	if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
		return false
	end
	local result 
	if alive(self._scroll) then 
	  result = self._scroll:mouse_pressed( button, x, y ) 
	end 
   
	if button == Idstring( "0" ) then 
		if alive(self._scroll) and self._scroll:panel():inside( x, y ) then

			for _, item in ipairs( self._buttons ) do
				if item:inside( x, y ) then

					if item.mod then
						self._inspecting = item:mod()
						managers.menu:open_menu( "blt_view_mod" )
						managers.menu_component:post_event( "menu_enter" )
					elseif item.parameters then
						local clbk = item:parameters().callback
						if clbk then
							clbk()
						end
					end

					return true
				end
			end

		end

	end

	return result
end

--------------------------------------------------------------------------------
-- Patch MenuComponentManager to create the BLT Mods component

Hooks:Add("MenuComponentManagerInitialize", "BLTModsGui.MenuComponentManagerInitialize", function(self)
	RaidMenuHelper:CreateMenu({
		name = "blt_mods",
		class = BLTModsGui,
		name_id = "blt_options_menu_blt_mods",
		back_callback = "perform_blt_save",
		inject_list = "raid_menu_left_options",
	})
end)