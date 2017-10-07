
Hooks:Register( "BLTOnBuildOptions" )

-- Create the menu node for BLT mods
local function add_blt_mods_node( menu )

	local new_node = {
		_meta = "node",
		name = "blt_mods",
		back_callback = "perform_blt_save close_blt_mods",
		menu_components = "blt_mods",
	}
	table.insert( menu, new_node )

	return new_node

end

-- Create the menu node for BLT mod options
local function add_blt_options_node( menu )

	local new_node = {
		_meta = "node",
		name = "blt_options",
		modifier = "BLTModOptionsInitiator",
		refresh = "BLTModOptionsInitiator",
		back_callback = "perform_blt_save",
		[1] = {
			_meta = "legend",
			name = "menu_legend_select"
		},
		[2] = {
			_meta = "legend",
			name = "menu_legend_back"
		},
		[3] = {
			_meta = "default_item",
			name = "back"
		},
		[4] = {
			_meta = "item",
			name = "back",
			text_id = "footer_back",
			back = true,
			previous_node = true,
			visible_callback = "is_pc_controller"
		}
	}
	table.insert( menu, new_node )

	return new_node

end

-- Create the menu node for BLT mod keybinds
local function add_blt_keybinds_node( menu )

	local new_node = {
		_meta = "node",
		name = "blt_keybinds",
		back_callback = "perform_blt_save",
		modifier = "BLTKeybindMenuInitiator",
		refresh = "BLTKeybindMenuInitiator",
		[1] = {
			_meta = "legend",
			name = "menu_legend_select"
		},
		[2] = {
			_meta = "legend",
			name = "menu_legend_back"
		},
		[3] = {
			_meta = "default_item",
			name = "back"
		},
		[4] = {
			_meta = "item",
			name = "back",
			text_id = "footer_back",
			back = true,
			previous_node = true,
			visible_callback = "is_pc_controller"
		}
	}
	table.insert( menu, new_node )

	return new_node

end

-- Create the menu node for the download manager
local function add_blt_downloads_node( menu )

	local new_node = {
		_meta = "node",
		name = "blt_download_manager",
		menu_components = "blt_download_manager",
		back_callback = "close_blt_download_manager",
		scene_state = "crew_management",
		[1] = {
			_meta = "default_item",
			name = "back"
		}
	}
	table.insert( menu, new_node )

	return new_node

end

local function inject_menu_options( menu, node_name, injection_point, items )

	for _, node in ipairs( menu ) do
		if node.name == node_name then
			for i, item in ipairs( node ) do
				if item.name == injection_point then

					for k = #items, 1, -1 do
						table.insert( node, i + 1, items[k] )
					end

				end
			end
		end
	end

end

-- Add the menu nodes for various menus
Hooks:Add("CoreMenuData.LoadDataMenu", "BLT.CoreMenuData.LoadDataMenu", function( menu_id, menu )
 

end)
