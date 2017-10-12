
local padding = 10

local massive_font = tweak_data.menu.pd2_massive_font
local large_font = tweak_data.menu.pd2_large_font
local medium_font = tweak_data.menu.pd2_medium_font
local small_font = tweak_data.menu.pd2_small_font

local massive_font_size = tweak_data.menu.pd2_massive_font_size
local large_font_size = tweak_data.menu.pd2_large_font_size
local medium_font_size = tweak_data.menu.pd2_medium_font_size
local small_font_size = tweak_data.menu.pd2_small_font_size

local function make_fine_text( text )
	local x,y,w,h = text:text_rect()
	text:set_size( w, h )
	text:set_position( math.round( text:x() ), math.round( text:y() ) )
end

--------------------------------------------------------------------------------

BLTUIButton = BLTUIButton or blt_class()

function BLTUIButton:init( panel, parameters )

	self._parameters = parameters

	-- Main panel
	self._panel = panel:panel({
		name = "panel",
		x = parameters.x or 0,
		y = parameters.y or 0,
		w = parameters.w or 128,
		h = parameters.h or 128,
		layer = 10
	})

	-- Background
	local bg_color = tweak_data.gui.colors.raid_list_background
	bg_color = (parameters.color or bg_color):with_alpha(bg_color.alpha)
	self._background = self._panel:rect({
		name = "bg",
		color =	bg_color,
		layer = -1
	})

	local title = self._panel:text({
		name = "title",
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		color = tweak_data.gui.colors.raid_white,
		text = parameters.title or "",
		align = "center",
		vertical = "top",
		wrap = true,
		word_wrap = true,
		w = self._panel:w() - padding * 2,
	})
	make_fine_text( title )
	title:set_w( self._panel:w() )
	title:set_center_x( self._panel:w() * 0.5 )
	if parameters.image then
		title:set_top( self._panel:h() * 0.5 )
	else
		title:set_bottom( self._panel:h() * 0.5 )
	end

	local desc = self._panel:text({
		name = "desc",
		font_size = small_font_size,
		font = small_font,
		layer = 10,
		color = title:color(),
		text = parameters.text or "",
		align = "center",
		vertical = "top",
		wrap = true,
		word_wrap = true,
		w = self._panel:w() - padding * 2,
	})
	make_fine_text( desc )
	desc:set_w( self._panel:w() )
	desc:set_center_x( self._panel:w() * 0.5 )
	desc:set_top( title:bottom() + 5 )
	if parameters.center_text then
		desc:set_center_y( self._panel:h() * 0.5 )
	end

	if parameters.image then

		local image = self._panel:bitmap({
			name = "image",
			texture = parameters.image,
			texture_rect = parameters.image_rect,
			color = parameters.color_image and title:color(),
			layer = 10,
			w = parameters.image_size or 64,
			h = parameters.image_size or 64,
		})
		image:set_center_x( self._panel:w() * 0.5 )
		image:set_top( padding )
	end

end

function BLTUIButton:panel()
	return self._panel
end

function BLTUIButton:title()
	return self._panel:child("title")
end

function BLTUIButton:text()
	return self._panel:child("desc")
end

function BLTUIButton:image()
	return self._panel:child("image")
end

function BLTUIButton:parameters()
	return self._parameters
end

function BLTUIButton:inside( x, y )
	return self._panel:inside( x, y )
end

function BLTUIButton:set_highlight( enabled, no_sound )
	if self._enabled ~= enabled then
		self._enabled = enabled
		local alpha = tweak_data.gui.colors.raid_list_background.alpha
		self._background:set_color( self._background:color():with_alpha(enabled and (alpha + 0.2) or alpha))
		if enabled and not no_sound then
			managers.menu_component:post_event( "highlight" )
		end
	end
end

--------------------------------------------------------------------------------

BLTDownloadControl = BLTDownloadControl or blt_class( BLTUIButton )

function BLTDownloadControl:init( panel, parameters )

	self._parameters = parameters
	local mod = parameters.update:GetParentMod()

	-- Main panel
	self._panel = panel:panel({
		x = parameters.x or 0,
		y = parameters.y or 0,
		w = parameters.w or 128,
		h = parameters.h or 128,
		layer = 10
	})

	-- Download button panel
	self._download_panel = self._panel:panel({
		w = math.min( self._panel:w() * 0.25, self._panel:h() )
	})
	self._download_panel:set_right( self._panel:w() )

	self._background = self._download_panel:rect({
		color =	parameters.color or tweak_data.gui.colors.raid_red,
		alpha = 0.8,
		layer = -1
	})
	local text_color = self._background:color():contrast()

	local image = self._download_panel:bitmap({
		name = "image",
		texture = "ui/atlas/raid_atlas_missions",
		rotation = 180,
		texture_rect = {120, 244, 52, 52},
		color = text_color,
		layer = 10,
	})
	image:set_world_center(self._download_panel:world_center())
	-- Patch notes button panel
	self._patch_panel = self._panel:panel({
		w = math.min( self._panel:w() * 0.25, self._panel:h() ),
		layer = 10
	})
	self._patch_panel:set_right( self._download_panel:x() - padding )

	self._patch_background = self._patch_panel:rect({
		color =	parameters.color or tweak_data.gui.colors.raid_red,
		alpha = 0.8,
		layer = -1
	})
	BoxGuiObject:new( self._patch_panel, { sides = { 1, 1, 1, 1 } } )

	self._patch_panel:text({
		font_size = small_font_size,
		font = small_font,
		layer = 10,
		color = text_color,
		text = managers.localization:text("blt_view_patch_notes"),
		align = "center",
		vertical = "center",
		w = self._patch_panel:w(),
		h = self._patch_panel:h(),
		wrap = true,
		word_wrap = true
	})

	-- Info panel
	self._info_panel = self._panel:panel({
		w = self._panel:w() - self._download_panel:w() - self._patch_panel:w() - padding * 2,
	})

	self._info_panel:rect({
		name = "background",
		color = Color.white:with_alpha(0.1),
		layer = -1,
		halign = "scale",
		valign = "scale"
	})

	BoxGuiObject:new( self._info_panel, { sides = { 1, 1, 1, 1 } } )

	local download_name = parameters.update:GetName() or "No Name"
	if mod:GetName() ~= download_name then
		download_name = download_name .. " (" .. mod:GetName() .. ")"
	end

	-- Mod image
	local image_path
	local image_size = self._info_panel:h() - padding * 2
	if mod:HasModImage() then
		image_path = mod:GetModImage()
	end

	if image_path then
		local image = self._info_panel:bitmap({
			name = "image",
			texture = image_path,
			layer = 10,
			x = padding,
			y = padding,
			w = image_size,
			h = image_size,
		})
	else

		local no_image_panel = self._info_panel:panel({
			x = padding,
			y = padding,
			w = image_size,
			h = image_size,
			layer = 10
		})
		BoxGuiObject:new( no_image_panel, { sides = { 1, 1, 1, 1 } } )

		local no_image_text = no_image_panel:text({
			name = "no_image_text",
			font_size = small_font_size * 0.8,
			font = small_font,
			layer = 10,
			text = managers.localization:text("blt_no_image"),
			align = "center",
			vertical = "center",
			w = no_image_panel:w(),
			h = no_image_panel:h()
		})

	end

	-- Download info
	local title = self._info_panel:text({
		name = "title",
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		text = download_name,
		align = "left",
		vertical = "top",
		x = padding * 2 + image_size,
		y = padding,
		w = self._info_panel:w() - padding * 3 - image_size,
		h = self._info_panel:h() - padding * 3,
	})

	local state = self._panel:text({
		name = "state",
		font_size = small_font_size,
		font = small_font,
		layer = 10,
		alpha = 0.8,
		text = managers.localization:text("blt_download_ready"),
		align = "left",
		vertical = "bottom",
		x = padding * 2 + image_size,
		y = padding,
		w = self._info_panel:w() - padding * 3 - image_size,
		h = self._info_panel:h() - padding * 3,
	})
	self._download_state = state

	local download_progress = self._info_panel:text({
		name = "download_progress",
		font_size = large_font_size,
		font = large_font,
		layer = 10,
		text = "100%",
		align = "right",
		vertical = "center",
		x = padding * 2 + image_size,
		y = padding,
		w = self._info_panel:w() - padding * 4 - image_size,
		h = self._info_panel:h() - padding * 2,
	})
	download_progress:set_visible( false )
	self._download_progress = download_progress

	self._download_progress_bg = self._info_panel:rect({
		color = tweak_data.gui.colors.raid_red,
		alpha = 0.4,
		layer = -1
	})
	self._download_progress_bg:set_w( 0 )
	self._download_progress_bg:set_visible( false )

end

function BLTDownloadControl:inside( x, y )
	return self._download_panel:inside( x, y ) or self._patch_panel:inside( x, y )
end

function BLTDownloadControl:set_highlight( enabled, no_sound )
end

function BLTDownloadControl:mouse_moved( button, x, y )

	local inside_download = self._download_panel:inside( x, y )
	if self._highlight_download ~= inside_download then
		self._background:set_color( inside_download and tweak_data.gui.colors.raid_red or (self:parameters().color or tweak_data.gui.colors.raid_red) )
		if inside_download and not no_sound then
			managers.menu_component:post_event( "highlight" )
		end
		self._highlight_download = inside_download
	end

	local inside_patch = self._patch_panel:inside( x, y )
	if self._highlight_patch ~= inside_patch then
		self._patch_background:set_color( inside_patch and tweak_data.gui.colors.raid_red or (self:parameters().color or tweak_data.gui.colors.raid_red) )
		if inside_patch and not no_sound then
			managers.menu_component:post_event( "highlight" )
		end
		self._highlight_patch = inside_patch
	end

end

function BLTDownloadControl:mouse_clicked( button, x, y )
	
	if button == Idstring( "0" ) then -- left click 
		
		if self._download_panel:inside( x, y ) then
			if not BLT.Downloads:get_download( self._parameters.update ) then
				BLT.Downloads:start_download( self._parameters.update )
				return true
			end
		end

		if self._patch_panel:inside( x, y ) then
			self._parameters.update:ViewPatchNotes()
			return true
		end
	
	end
	
end

function BLTDownloadControl:update_download( download )

	self._background:set_color( tweak_data.menu.default_disabled_text_color )

	local percent = (download.bytes or 0) / (download.total_bytes or 1)
	if download.state == "complete" then
		self:_update_complete( download, percent )
	elseif download.state == "failed" then
		self:_update_failed( download, percent )
	elseif download.state == "verifying" then
		self:_update_verifying( download, percent )
	elseif download.state == "extracting" then
		self:_update_extracting( download, percent )
	elseif download.state == "saving" then
		self:_update_saving( download, percent )
	elseif download.state == "downloading" then
		self:_update_download( download, percent )
	elseif download.state == "waiting" then
		self:_update_waiting( download, percent )
	end

end

function BLTDownloadControl:_update_complete( download, percent )
	self._download_state:set_text( managers.localization:text("blt_download_done") )
	self._download_progress:set_text( "100%" )
	self._download_progress_bg:set_visible( false )
end

function BLTDownloadControl:_update_failed( download, percent )
	self._download_state:set_text( managers.localization:text("blt_download_failed") )
	self._download_progress:set_text( "100%" )
	self._download_progress_bg:set_visible( false )
end

function BLTDownloadControl:_update_verifying( download, percent )
	self._download_state:set_text( managers.localization:text("blt_download_verifying") )
	self._download_progress:set_text( "100%" )
	self._download_progress_bg:set_visible( false )
end

function BLTDownloadControl:_update_extracting( download, percent )
	self._download_state:set_text( managers.localization:text("blt_download_extracting") )
	self._download_progress:set_text( "100%" )
	self._download_progress_bg:set_visible( false )
	self._download_progress_bg:set_w( self._info_panel:w() )
end

function BLTDownloadControl:_update_saving( download, percent )
	self._download_state:set_text( managers.localization:text("blt_download_saving") )
	self._download_progress:set_text( "100%" )
	self._download_progress_bg:set_w( self._info_panel:w() )
end

function BLTDownloadControl:_update_download( download, percent )
	local macros = {
		bytes = tostring(download.bytes),
		total_bytes = tostring(download.total_bytes)
	}
	self._download_state:set_text( managers.localization:text("blt_download_downloading", macros) )
	self._download_progress:set_visible( true )
	self._download_progress:set_text( tostring(math.floor(percent * 100)) .. "%" )
	self._download_progress_bg:set_visible( true )
	self._download_progress_bg:set_w( percent * self._info_panel:w() )
end

function BLTDownloadControl:_update_waiting( download, percent )
	self._download_state:set_text( managers.localization:text("blt_download_waiting") )
end
