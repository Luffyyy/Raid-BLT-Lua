
BLTDownloadManagerGui = BLTDownloadManagerGui or blt_class(BLTCustomMenu)

local padding = 10
local massive_font = tweak_data.menu.pd2_massive_font
local large_font = tweak_data.menu.pd2_large_font
local massive_font_size = tweak_data.menu.pd2_massive_font_size
local large_font_size = tweak_data.menu.pd2_large_font_size

function BLTDownloadManagerGui:init(ws, fullscreen_ws, node)
	self._downloads_map = {}
	BLTDownloadManagerGui.super.init(self, ws, fullscreen_ws, node, "blt_download_manager")
end

function BLTDownloadManagerGui:close()
	BLTDownloadManagerGui.super.close(self)
	BLT.Downloads:flush_complete_downloads()
end

function BLTDownloadManagerGui:_setup()

	-- Background
	self._background = self._fullscreen_panel:rect({
		color = Color.black,
		alpha = 0.4,
		layer = -1
	})

	-- Title
	local title = self._panel:text({
		name = "title",
		x = padding,
		y = padding,
		font_size = large_font_size,
		font = large_font,
		visible = false,
		h = large_font_size,
		layer = 10,
		color = tweak_data.screen_colors.title,
		text = managers.localization:text("blt_download_manager"),
		align = "left",
		vertical = "top",
	})

	-- Download scroll panel
	local scroll_panel = self._panel:panel({
		h = self._panel:h() - large_font_size - padding * 2,
		y = large_font_size + padding,
	})
	BoxGuiObject:new(scroll_panel:panel({layer=100}), { sides = { 1, 1, 1, 1 } })
	BoxGuiObject:new(scroll_panel:panel({layer=100}), { sides = { 1, 1, 2, 2 } })

	self._scroll = ScrollablePanel:new( scroll_panel, "downloads_scroll", {} )

	-- Add download items
	local h = 80
	for i, download in ipairs( BLT.Downloads:pending_downloads() ) do

		local data = {
			y = (h + padding) * (i - 1),
			w = self._scroll:canvas():w(),
			h = h,
			update = download.update,
		}
		local button = BLTDownloadControl:new( self._scroll:canvas(), data )
		table.insert( self._buttons, button )

		self._downloads_map[ download.update:GetId() ] = button

	end

	local num_downloads = table.size( BLT.Downloads:pending_downloads() )
	if num_downloads > 0 then
		local w, h = 80, 80
		local button = BLTUIButton:new( self._scroll:canvas(), {
			x = self._scroll:canvas():w() - w,
			y = (h + padding) * num_downloads,
			w = w,
			h = h,
			text = managers.localization:text("blt_download_all"),
			center_text = true,
			callback = callback( self, self, "clbk_download_all" )
		} )
		table.insert( self._buttons, button )
	end

	-- Update scroll
	self._scroll:update_canvas_size()

end

function BLTDownloadManagerGui:clbk_download_all()
	BLT.Downloads:download_all()
end

--------------------------------------------------------------------------------

function BLTDownloadManagerGui:update(t, dt)
	for _, download in ipairs( BLT.Downloads:downloads() ) do
		local id = download.update:GetId()
		local button = self._downloads_map[ id ]
		if button then
			button:update_download( download )
		end
	end
end

-------------------------------------------------------------------------------
-- Patch MenuComponentManager to create the BLT Download Manager component
Hooks:Add("MenuComponentManagerInitialize", "BLTDownloadManagerGui.MenuComponentManagerInitialize", function(self)
	RaidMenuHelper:CreateMenu({
		name = "blt_download_manager",
		back_callback = "perform_blt_save",
		class = BLTDownloadManagerGui
	})
end)