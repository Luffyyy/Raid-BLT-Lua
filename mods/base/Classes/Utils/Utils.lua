-------------------------------------------------
--New functions / Utils class
-------------------------------------------------

Utils = Utils or {}
_G.Utils = Utils

--[[
	CloneClass( class, clone_key )
		Copies an existing class into an orig table, so that class functions can be overwritten and called again easily
    class, The class table to clone
    clone_key the key for the cloned table of the class, default is 'orig'
    it's recommended to use Hooks instead of CloneClass.
]]
function _G.CloneClass(class, clone_key)
    clone_key = clone_key or "orig"
	if not class[clone_key] then
		class[clone_key] = clone(class)
	end
end

--[[
	PrintTable( tbl, level )
		Prints the contents of a table to your console
		Warning, may cause game slowdown if the table is fairly large, only for debugging purposes
	tbl, The table to print to console
    level, how much levels should it print, for example 2 levels would fully print this table {x = {y = "z"}}
    the rest of the params should not be written, they're used as recursive params.
]]
function _G.PrintTable(tbl, level, key, tab)
	level = level or 1
	tab = tab or 1 
	level = level - 1
	local tabs = string.rep('	', tab)
	if level == -1 then
		log(string.format(tabs.."['%s'] = %s,", tostring(key), tostring(tbl)))
		return
	end
	local fixed = type(tbl) == "userdata" and getmetatable(tbl) or tbl or {}
	log(tabs .. (key and "['"..key.."'] = " or "") .."{")
	tabs = string.rep('	', tab+1)
	for k,v in pairs(fixed) do
		if type(v) == "table" then
			PrintTable(v, level, k, tab+1)
		else
			log(string.format(tabs.."['%s'] = %s,", tostring(k), tostring(v)))
		end
	end
	log(tabs.."}")
end


--[[
	SaveTable( tbl, file )
		Saves the contents of a table to the specified file
	tbl, 	The table to save to a file
	file, 	The path (relative to raid_win64_d3d9_release.exe) and file name to save the table to
]]
function _G.SaveTable( tbl, file )
	Utils.DoSaveTable( tbl, {}, file, nil, "" )
end

function Utils.DoSaveTable( tbl, cmp, fileName, fileIsOpen, preText )

	local file = nil
	if fileIsOpen == nil then
		file = io.open(fileName, "w")
	else
		file = fileIsOpen
	end

	cmp = cmp or {}
	if tbl and type(tbl) == "table" then
		for k, v in pairs(tbl) do
			if type(v) == "table" and not cmp[v] then
				cmp[v] = true
				file:write( preText .. string.format("[\"%s\"] -> table", tostring (k)) .. "\n" )
				Utils.DoSaveTable(v, cmp, fileName, file, preText .. "\t")
			else
				file:write( preText .. string.format( "\"%s\" -> %s", tostring(k), tostring(v) ) .. "\n" )
			end
		end
	else
		file:write( preText .. tostring(tbl) .. "\n")
	end

	if fileIsOpen == nil then
		file:close()
	end

end

--[[
	IsInGameState()
		Returns true if you are in GameState (loadout, ingame, end screens like victory and defeat) and false 
		if you are not.
]]
function Utils:IsInGameState()
	if not game_state_machine then
		return false
	end
	return string.find(game_state_machine:current_state_name(), "game")
end

--[[
	IsInLoadingState()
		Returns true if you are in a loading state, and false if you are not.
]]
function Utils:IsInLoadingState()
	if not BaseNetworkHandler then
		return false
	end
	return BaseNetworkHandler._gamestate_filter.waiting_for_players[ game_state_machine:last_queued_state_name() ]
end

--[[
	IsInHeist()
		Returns true if you are currently in game (you're able to use your weapons, spot, call teammates etc) and
		false if you are not. Only returns true if currently ingame, does not check for GameState like IsInGameState().
]]
function Utils:IsInHeist()
	if not BaseNetworkHandler then
		return false
	end
	return BaseNetworkHandler._gamestate_filter.any_ingame_playing[ game_state_machine:last_queued_state_name() ]
end

--[[
	IsInCustody()
		Returns true if the local player is in custody, and false if not.
]]
function Utils:IsInCustody()
	local player = managers.player:local_player()
	local in_custody = false
	if managers and managers.trade and not alive( player ) and managers.network:session() and managers.network:session():local_peer() and managers.network:session():local_peer():id() then
		in_custody = managers.trade:is_peer_in_custody(managers.network:session():local_peer():id())
	end
	return in_custody
end

--[[
	IsCurrentPrimaryOfCategory(type)
		Checks current primary weapon's weapon class.
	type, the weapon class to check for.  "assault_rifle", "snp", "shotgun"; refer to weapontweakdata
]]
function Utils:IsCurrentPrimaryOfCategory(type)
	local primary = managers.blackmarket:equipped_primary()
	if primary then
		local category = tweak_data.weapon[ primary.weapon_id ].category
		return category == string.lower(type)
	end
	return false
end

--[[
	IsCurrentSecondaryOfCategory(type)
		Checks current secondary weapon's weapon class.
	type, the weapon class to check for.  "pistol", "shotgun", "smg"; refer to weapontweakdata
]]
function Utils:IsCurrentSecondaryOfCategory(type)
	local secondary = managers.blackmarket:equipped_secondary()
	if secondary then
		local category = tweak_data.weapon[ secondary.weapon_id ].category
		return category == string.lower(type)
	end
	return false
end

--[[
	IsCurrentWeapon(type)
		Checks current equipped weapon's name ID.
	type, the weapon's ID.  "aug", "glock_18c", "new_m4", "colt_1911"; refer to weaponfactorytweakdata
]]
function Utils:IsCurrentWeapon(type)
	local weapon = managers.player:local_player():inventory():equipped_unit():base()._name_id
	if weapon then
		return weapon == string.lower(type)
	end
	return false
end

--[[
	IsCurrentWeaponPrimary()
		Checks if current equipped weapon is your primary weapon.
]]
function Utils:IsCurrentWeaponPrimary()
	local weapon = managers.player:local_player():inventory():equipped_unit():base():selection_index()
	local curstate = managers.player._current_state
	if weapon then
		return (curstate ~= "mask_off" and weapon == 2)
	end
end

--[[
	IsCurrentWeaponPrimary()
		Checks if current equipped weapon is your secondary weapon.
]]
function Utils:IsCurrentWeaponSecondary()
	local weapon = managers.player:local_player():inventory():equipped_unit():base():selection_index()
	local curstate = managers.player._current_state
	if weapon then
		return (curstate ~= "mask_off" and weapon == 1)
	end
end

--[[
	Utils:GetPlayerAimPos( player, maximum_range )
		Gets the point in the world, as a Vector3, where the player is aiming at
	player, 		The player to get the aiming position of
	maximum_range, 	The maximum distance to check for a point (default 100000, 1km)
	return, 		A Vector3 containing the location that the player is looking at, or false if the player was not looking at anything
			or was looking at something past the maximum_range
]]
function Utils:GetPlayerAimPos( player, maximum_range )
	local ray = self:GetCrosshairRay(player:camera():position(), player:camera():position() + player:camera():forward() * (maximum_range or 100000))
	if not ray then
		return false
	end
	return ray.hit_position
end

--[[
	Utils:GetCrosshairRay( from, to, slot_mask )
		Gets a ray between two points and checks for a collision with the slot_mask along the ray
	from, 		The starting position of the ray, defaults to the player's head
	to, 		The ending position of the ray, defaults to 1m in from of the player's head
	slot_mask, 	The collision group to check against the ray, defaults to all objects the player can shoot
	return, 	A table containing the ray information
]]
function Utils:GetCrosshairRay( from, to, slot_mask )

	slot_mask = slot_mask or "bullet_impact_targets"

	if not from then
		local player = managers.player:player_unit()
		if player then
			from = player:movement():m_head_pos()
		else
			from = managers.viewport:get_current_camera_position()
		end
	end

	if not to then
		to = Vector3()
		mvector3.set( to, player:camera():forward() )
		mvector3.multiply( to, 20000 )
		mvector3.add( to, from )
	end

	local colRay = World:raycast("ray", from, to, "slot_mask", managers.slot:get_mask(slot_mask))
	return colRay

end

--[[
	Utils:ToggleItemToBoolean( item )
		Gets the string value of a toggle item and converts it to a boolean value
	item, 		The toggle menu item to get a boolean value from
	return, 	True if the toggle item is on, false otherwise
]]
function Utils:ToggleItemToBoolean( item )
	return item:value() == "on" and true or false
end

--[[
	Utils:EscapeURL( item )
		Escapes characters in a URL to turn it into a usable URL
	input_url, 	The url to escape the characters of
	return, 	A url string with escaped characters
]]
function Utils:EscapeURL( input_url )
	local url = input_url:gsub(" ", "%%20")
	url = url:gsub("!", "%%21")
	url = url:gsub("#", "%%23")
	url = url:gsub("-", "%%2D")
	return url
end

function Utils:TimestampToEpoch( year, month, day )
	-- Adapted from http://stackoverflow.com/questions/4105012/convert-a-string-date-to-a-timestamp
	local offset = os.time() - os.time(os.date("!*t"))
	local time = os.time({
		day = day,
		month = month,
		year = year,
	})
	return (time or 0) + (offset or 0)
end

--TODO: Does it work in raid?
function Utils:RefreshCurrentNode()
    local selected_node = managers.menu:active_menu().logic:selected_node()
    managers.menu:active_menu().renderer:refresh_node(selected_node)
    local selected_item = selected_node:selected_item()
    selected_node:select_item(selected_item and selected_item:name())
    managers.menu:active_menu().renderer:highlight_item(selected_item)
end

function Utils:CheckParamsValidty(tbl, schema)
    local ret = true
    for i = 1, #schema.params do
        local var = tbl[i]
        local sc = schema.params[i]
        if not self:CheckParamValidty(schema.func_name, i, var, sc.type, sc.allow_nil) then
            ret = false
        end
    end
    return ret
end

function Utils:CheckParamValidty(func_name, vari, var, desired_type, allow_nil)
    if (var == nil and not allow_nil) or type(var) ~= desired_type then
        log(string.format("[%s] Parameter #%s, expected %s, got %s", func_name, vari, desired_type, tostring(var and type(var) or nil)))
        return false
    end

    return true
end

function Utils:GetSubValues(tbl, key)
    local new_tbl = {}
    for i, vals in pairs(tbl) do
        if vals[key] then
            new_tbl[i] = vals[key]
        end
    end

    return new_tbl
end

local searchTypes = {
    "Vector3",
    "Rotation",
    "Color",
    "callback"
}

function Utils:normalize_string_value(value)
    if type(value) ~= "string" then
        return value
    end

	for _, search in pairs(searchTypes) do
		if string.begins(value, search) then
			value = loadstring("return " .. value)()
			break
		end
	end
	return value
end

function Utils:StringToTable(global_tbl_name, global_tbl, silent)
    local global_tbl = global_tbl or _G
    if string.find(global_tbl_name, "%.") then
        local global_tbl_split = string.split(global_tbl_name, "[.]")

        for _, str in pairs(global_tbl_split) do
            global_tbl = rawget(global_tbl, str)
            if not global_tbl then
                if not silent then
                    BLT:log("[ERROR] Key " .. str .. " does not exist in the current global table.")
                end
                return nil
            end
        end
    else
        global_tbl = rawget(global_tbl, global_tbl_name)
        if not global_tbl then
            if not silent then
                BLT:log("[ERROR] Key " .. global_tbl_name .. " does not exist in the current global table.")
            end
            return nil
        end
    end

    return global_tbl
end

function Utils:RemoveAllSubTables(tbl)
    for i, sub in pairs(tbl) do
        if type(sub) == "table" then
            tbl[i] = nil
        end
    end
    return tbl
end

function Utils:RemoveAllNumberIndexes(tbl, shallow)
	if not tbl then return nil end

    if type(tbl) ~= "table" then
        return tbl
    end

	if shallow then
		for i, sub in ipairs(tbl) do
			tbl[i] = nil
		end
	else
	    for i, sub in pairs(tbl) do
	        if tonumber(i) ~= nil then
	            tbl[i] = nil
	        elseif type(sub) == "table" and not shallow then
	            tbl[i] = self:RemoveAllNumberIndexes(sub)
	        end
	    end
	end
    return tbl
end

function Utils:GetNodeByMeta(tbl, meta, multi)
    if not tbl then return nil end
    local t = {}
    for _, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            if multi then
                table.insert(t, v)
            else
                return v
            end
        end
    end

    return multi and t or nil
end

function Utils:GetIndexNodeByMeta(tbl, meta, multi)
    if not tbl then return nil end
    local t = {}
    for i, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            if multi then
                table.insert(t, i)
            else
                return i
            end
        end
    end

    return multi and t or nil
end

function Utils:CleanCustomXmlTable(tbl, shallow)
    if not tbl then return nil end

    for i, v in pairs(tbl) do
        if type(v) == "table" then
            if tonumber(i) == nil then
                tbl[i] = nil
            elseif not shallow then
                self:CleanCustomXmlTable(v, shallow)
            end
        end
    end

    return tbl
end

function Utils:RemoveNonNumberIndexes(tbl)
	if not tbl then return nil end

    if type(tbl) ~= "table" then
        return tbl
    end

    for i, _ in pairs(tbl) do
        if tonumber(i) == nil then
            tbl[i] = nil
        end
    end

    return tbl
end

function Utils:RemoveMetas(tbl, shallow)
	if not tbl then return nil end
	tbl._meta = nil

	if not shallow then
	    for i, data in pairs(tbl) do
	        if type(data) == "table" then
	            self:RemoveMetas(data, shallow)
	        end
	    end
	end
	return tbl
end

local encode_chars = {
	["\t"] = "%09",
	["\n"] = "%0A",
	["\r"] = "%0D",
	[" "] = "+",
	["!"] = "%21",
	['"'] = "%22",
	[":"] = "%3A",
	["{"] = "%7B",
	["}"] = "%7D",
	["["] = "%5B",
	["]"] = "%5D",
	[","] = "%2C"
}
function Utils:UrlEncode(str)
	if not str then
		return ""
	end

	return string.gsub(str, ".", encode_chars)
end

Utils.Path = {}
_G.Path = Utils.Path

Utils.Path._separator_char = "/"

function Utils.Path:GetDirectory(path)
	if not path then return nil end
	local split = string.split(self:Normalize(path), self._separator_char)
	table.remove(split)
	return table.concat(split, self._separator_char)
end

function Utils.Path:GetFileName(str)
	if string.ends(str, self._separator_char) then
		return nil
	end
	str = self:Normalize(str)
	return table.remove(string.split(str, self._separator_char))
end

function Utils.Path:GetFileNameWithoutExtension(str)
    local filename = self:GetFileName(str)
    if not filename then
        return nil
    end

    if string.find(filename, "%.") then
        local split = string.split(filename, "%.")
        table.remove(split)
        filename = table.concat(split, ".")
    end
    return filename
end

function Utils.Path:GetFileExtension(str)
	local filename = self:GetFileName(str)
	if not filename then
		return nil
	end
    local ext = ""
	if string.find(filename, "%.") then
		local split = string.split(filename, "%.")
		ext = split[#split]
	end
	return ext
end

function Utils.Path:Normalize(str)
	if not str then return nil end

	--Clean seperators
	str = string.gsub(str, ".", {
		["\\"] = self._separator_char,
		--["/"] = self._separator_char,
	})

	str = string.gsub(str, "([%w+]/%.%.)", "")
	return str
end

function Utils.Path:Combine(start, ...)
	local paths = {...}
	local final_string = start
	for i, path_part in pairs(paths) do
		if string.begins(path_part, ".") then
			path_part = string.sub(path_part, 2, #path_part)
		end
		if not string.ends(final_string, self._separator_char) and not string.begins(path_part, self._separator_char) then
			final_string = final_string .. self._separator_char
		end
		final_string = final_string .. path_part
	end

	return self:Normalize(final_string)
end

Utils.Input = Utils.Input or class()

function Utils.Input:Class() return Input:keyboard() end
function Utils.Input:Id(str) return str:id() end

--Keyboard
function Utils.Input:Down(key) return self:Class():down(self:Id(key)) end
function Utils.Input:Released(key) return self:Class():released(self:Id(key)) end
function Utils.Input:Pressed(key) return self:Class():pressed(self:Id(key)) end
function Utils.Input:Trigger(key, clbk) return self:Class():add_trigger(self:Id(key), SafeClbk(clbk)) end
function Utils.Input:RemoveTrigger(trigger) return self:Class():remove_trigger(trigger) end
function Utils.Input:TriggerRelease(key, clbk) return self:Class():add_release_trigger(self:Id(key), SafeClbk(clbk)) end
--Mouse
Utils.MouseInput = Utils.MouseInput or class(Utils.Input)
function Utils.MouseInput:Class() return Input:mouse() end
--Keyboard doesn't work without Idstring however mouse works and if you don't use Idstring you can use strings like 'mouse 0' to differentiate between keyboard and mouse
--For example keyboard has the number 0 which is counted as left mouse button for mouse input, this solves it.
function Utils.MouseInput:Id(str) return str end

function Utils.Input:TriggerDataFromString(str, clbk)
    local additional_key
    local key = str
    if str:match("+") then
        local split = string.split(str, "+")
        key = split[1]
        additional_key = split[2]
    end
    return {key = key, additional_key = additional_key, clbk = clbk}
end

function Utils.Input:Triggered(trigger, check_mouse_too)
    if not trigger.key then
        return false
    end
    if check_mouse_too and trigger.key:match("mouse") then
        return Utils.MouseInput:Pressed(trigger.key)
    end
    if trigger.additional_key then
        if self:Down(trigger.key) and self:Pressed(trigger.additional_key) then
            return true
        end
    elseif self:Pressed(trigger.key) then
        return true
    end
    return false
end

function NotNil(...)
    local args = {...}
    for k, v in pairs(args) do
        if v ~= nil or k == #args then
            return v
        end
    end
    return nil
end

function SimpleClbk(func, ...)
    local args = {...}
    return function(...) return func(unpack(table.list_add(args, {...}))) end
end

function SafeClbk(func, ...)
    local params = {...}
    return function(...)
        local p = {...}
        local success, ret = pcall(function() ret = func(unpack(params), unpack(p)) end)
        if not success then
            BLT:log("[Safe Callback Error] %s", tostring(ret and ret.code or ""))
            return nil
        end
        return ret
    end
end

function ClassClbk(clss, func, ...)
    local f = clss[func]
    if not f then
        BLT:log("[Callback Error] Function named %s was not found in the given class", tostring(func))
        return function() end
    end
    return SimpleClbk(f, clss, ...)
end


--Pretty much CoreClass.type_name with support for tables.
function type_name(value)
    local t = type(value)
    if t == "userdata" or t == "table" and value.type_name then
        return value.type_name
    end
    return t
end

--Quickly animate stuff
function anim_dt(dont_pause)
    local dt = coroutine.yield()
    if Application:paused() and not dont_pause then
        dt = TimerManager:main():delta_time()
    end
    return dt
end

function anim_over(seconds, f, dont_pause)
	local t = 0

	while true do
		local dt = anim_dt(dont_pause)
		t = t + dt

		if seconds <= t then
			break
		end

		f(t / seconds, t)
	end

	f(1, seconds)
end

function anim_wait(seconds, dont_pause)
	local t = 0

	while t < seconds do
		local dt = anim_dt(dont_pause)
		t = t + dt
	end
end

function play_anim_thread(params, o)
	o:script().animating = true
	
    local easing = PD2Easing[params.easing or "linear"]
    local time = params.time or 0.25
    local clbk = params.callback
    local wait_time = params.wait
	local after = params.after
    local set = params.set or params

    if wait_time then
        time = time + wait_time
        anim_wait(wait_time)
    end
    
    for param, value in pairs(set) do
        if type(value) ~= "table" then
            set[param] = {value = value}
        end
        set[param].old_value = set[param].old_value or o[param](o)
    end

	anim_over(time, function (t)
        for param, anim in pairs(set) do
            local ov = anim.old_value
            local v = anim.value
            local typ = type_name(v)
            if typ == "Color" then
                o:set_color(Color(easing(ov.a, v.a, t), easing(ov.r, v.r, t), easing(ov.g, v.g, t), easing(ov.b, v.b, t)))
            else
                o["set_"..param](o, anim.sticky and v or easing(ov, v, t))
            end
            if after then after() end
        end
    end)
    --last loop
    for param, anim in pairs(set) do
        local v = anim.value
        local typ = type_name(v)        
        if typ == "Color" then
            o:set_color(v)
        else
            o["set_"..param](o, v)
        end
        if after then after() end
    end

    o:script().animating = nil    
    if clbk then
        clbk()
    end
end

function playing_anim(o)
    return o:script().animating
end

function stop_anim(o)
    o:stop()
    o:script().animating = nil
end

function play_anim(o, params)
    if not alive(o) then
        return
    end
    if playing_anim(o) and params.stop ~= false then
        stop_anim(o)
    end
    o:animate(SimpleClbk(play_anim_thread, params))
end

-- just more lightweight
function play_color(o, color, params)
    if not alive(o) then
        return
    end
    params = params or {}
    if playing_anim(o) and params.stop ~= false then
        stop_anim(o)
    end
    local easing = PD2Easing[params.easing or "linear"]
    local time = params.time or 0.25
    local clbk = params.callback
    local wait_time = params.wait
    local ov = o:color()
    if color then
        o:animate(function()
            o:script().animating = true        
            if wait_time then
                time = time + wait_time
                anim_wait(wait_time)
            end
            anim_over(time, function (t)
                o:set_color(Color(easing(ov.a, color.a, t), easing(ov.r, color.r, t), easing(ov.g, color.g, t), easing(ov.b, color.b, t)))
            end)
            o:set_color(color)
            o:script().animating = nil            
            if clbk then clbk() end
        end)
    end
end

function play_value(o, value_name, value, params)
    if not alive(o) then
        return
    end
    params = params or {}    
    if playing_anim(o) and params.stop ~= false then
        stop_anim(o)
    end
    local easing = PD2Easing[params.easing or "linear"]
    local time = params.time or 0.25
    local clbk = params.callback
    local wait_time = params.wait
    local ov = o[value_name](o)
    local func = ClassClbk(o, "set_"..value_name)
    if value then
        o:animate(function()
            o:script().animating = true
            if wait_time then
                time = time + wait_time
                anim_wait(wait_time)
            end
            anim_over(time, function (t)
                func(easing(ov, value, t))
            end)
            func(value)
            o:script().animating = nil
            if clbk then clbk() end
        end)
    end
end

-------------------------------------------------
--Modification of already existing classes
-------------------------------------------------

Vector3 = Vector3 or {}
Vector3.StringFormat = "%08f,%08f,%08f"
Vector3.MatchFormat = "([-0-9.]+),([-0-9.]+),([-0-9.]+)"

--[[
	Vector3.ToString( v )
		Converts a Vector3 to a string, useful in conjunction with Networking
	v, 			The Vector3 to convert to a formatted string
	return, 	A formatted string containing the data of the Vector3
]]
function Vector3.ToString( v )
	return string.format( Vector3.StringFormat, v.x, v.y, v.z )
end

--[[
	string.ToVector3( string )
		Converts a formatted string to a Vector3, useful in conjunction with Networking
	string, 	The string to convert to a Vector3
	return, 	A Vector3 of the converted string or nil if no conversion could be made
]]
function string.ToVector3( string )
	local x, y, z = string:match( Vector3.MatchFormat )
	if x ~= nil and y ~= nil and z ~= nil then
		return Vector3( tonumber(x), tonumber(y), tonumber(z) )
	end
	return nil
end


--[[
	string.is_nil_or_empty( str )
		Returns if a string exists or not
	str, 		The string to check if it exists or is empty
	return, 	Returns false if the string is empty ("") or nil, true otherwise
]]
function string.is_nil_or_empty( str )
	return str == "" or str == nil
end

--[[
	math.round_with_precision( num, idp )
		Rounds a number to the specified precision (decimal places)
	num, 		The number to round
	idp, 		The number of decimal places to round to (0 default)
	return, 	The input number rounded to the input precision (or floored integer)
]]
function math.round_with_precision( num, idp )
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function string.pretty2(str)
    str = tostring(str)
    return str:gsub("([^A-Z%W])([A-Z])", "%1 %2"):gsub("([A-Z]+)([A-Z][^A-Z$])", "%1 %2")
end

function string.key(str)
    local ids = Idstring(str)
    local key = ids:key()
    return tostring(key)
end

-- From: http://stackoverflow.com/questions/7183998/in-lua-what-is-the-right-way-to-handle-varargs-which-contains-nil
function table.pack(...)
  return { n = select("#", ...), ... }
end

function table.merge(og_table, new_table)
    for i, data in pairs(new_table) do
        i = type(data) == "table" and data.index or i
        if type(data) == "table" and type(og_table[i]) == "table" then
            og_table[i] = table.merge(og_table[i], data)
        else
            og_table[i] = data
        end
    end
    return og_table
end

function table.map_indices(og_table)
    local tbl = {}
    for i=1, #og_table do
        table.insert(tbl, i)
    end
    return tbl
end

--When you want to merge but don't want to merge things like menu items together.
function table.careful_merge(og_table, new_table)
    for i, data in pairs(new_table) do
        i = type_name(data) == "table" and data.index or i
        if type_name(data) == "table" and type_name(og_table[i]) == "table" then
            og_table[i] = table.merge(og_table[i], data)
        else
            og_table[i] = data
        end
    end
    return og_table
end

function table.add_merge(og_table, new_table)
	for i, data in pairs(new_table) do
		i = (type(data) == "table" and data.index) or i
        if type(i) == "number" and og_table[i] then
            table.insert(og_table, data)
        else
    		if type(data) == "table" and og_table[i] then
    			og_table[i] = table.add_merge(og_table[i], data)
    		else
    			og_table[i] = data
    		end
        end
	end
	return og_table
end

function table.add(t, items)
	for i, sub_item in ipairs(items) do
		if t[i] then
			table.insert(t, sub_item)
		else
			t[i] = sub_item
		end
	end
	return t
end

function table.search(tbl, search_term)
    local search_terms = {search_term}

    if string.find(search_term, "/") then
        search_terms = string.split(search_term, "/")
    end

	local index
    for _, term in pairs(search_terms) do
        local term_parts = {term}
        if string.find(term, ";") then
            term_parts = string.split(term, ";")
        end
        local search_keys = {
            params = {}
        }
        for _, term in pairs(term_parts) do
            if string.find(term, "=") then
                local term_split = string.split(term, "=")
                search_keys.params[term_split[1]] = assert(loadstring("return " .. term_split[2]))()
				if not search_keys.params[term_split[1]] then
					BLT:log(string.format("[ERROR] An error occured while trying to parse the value %s", term_split[2]))
				end
            elseif not search_keys._meta then
                search_keys._meta = term
            end
        end

		local found_tbl = false
        for i, sub in ipairs(tbl) do
            if type(sub) == "table" then
                local valid = true
                if search_keys._meta and sub._meta ~= search_keys._meta then
                    valid = false
                end

                for k, v in pairs(search_keys.params) do
                    if sub[k] == nil or (sub[k] and sub[k] ~= v) then
                        valid = false
                        break
                    end
                end

                if valid then
                    if i == 1 then
                        if tbl[sub._meta] then
                            tbl[sub._meta] = sub
                        end
                    end

                    tbl = sub
					found_tbl = true
					index = i
                    break
                end
            end
        end
		if not found_tbl then
			return nil
		end
    end
	return index, tbl
end

function table.custom_insert(tbl, add_tbl, pos_phrase)
	if not pos_phrase then
		table.insert(tbl, add_tbl)
		return
	end

	if tonumber(pos_phrase) ~= nil then
		table.insert(tbl, pos_phrase, add_tbl)
	else
		local phrase_split = string.split(pos_phrase, ":")
		local i, _ = table.search(tbl, phrase_split[2])

		if not i then
			BLT:log(string.format("[ERROR] Could not find table for relative placement. %s", pos_phrase))
			table.insert(tbl, add_tbl)
		else
			i = phrase_split[1] == "after" and i + 1 or i
			table.insert(tbl, i, add_tbl)
		end
	end
end

local special_params = {"search", "index"}
function table.script_merge(base_tbl, new_tbl)
    for i, sub in pairs(new_tbl) do
        if type(sub) == "table" then
            if tonumber(i) ~= nil then
                if sub.search then
                    local index, found_tbl = table.search(base_tbl, sub.search)
                    if found_tbl then
                        table.script_merge(found_tbl, sub)
                    end
                else
                    table.custom_insert(base_tbl, sub, sub.index)
					if not base_tbl[sub._meta] then
						base_tbl[sub._meta] = sub
					end
					for _, param in pairs(special_params) do
						sub[param] = nil
					end
                end
            end
        elseif not table.contains(special_params, i) then
            base_tbl[i] = sub
        end
    end
end

Color = Color or {}

--If only Color supported alpha for hex :P
function Color:from_hex(hex)
    if not hex or type(hex) ~= "string" then
        log(debug.traceback())
        return Color()
    end
    if hex:match("#") then
        hex = hex:sub(2)
    end
    local col = {}
    for i=1,8,2 do
        local num = tonumber(hex:sub(i, i+1), 16)
        if num then
            table.insert(col, num / 255)
        end
    end
    return Color(unpack(col))
end

function Color:to_hex()
    local s = "%x"
    local result = ""
    for _, v in pairs({self.a < 1 and self.a or nil,self.r,self.g,self.b}) do
        local hex = s:format(255*v)
        if hex:len() == 0 then hex = "00" end
        if hex:len() == 1 then hex = "0"..hex end
        result = result .. hex
    end
    return result
end

function Color:contrast(white, black)
    local col = {r = self.r, g = self.g, b = self.b}

    for k, c in pairs(col) do
        if c <= 0.03928 then 
            col[k] = c/12.92 
        else 
            col[k] = ((c+0.055)/1.055) ^ 2.4 
        end
    end
    local L = 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b
    local color = white or Color.white
    if L > 0.179 and self.a > 0.5 then
        color = black or Color.black 
    end
    return color
end

mrotation = mrotation or {}

function mrotation.copy(rot)
    if rot then
        return Rotation(rot:yaw(), rot:pitch(), rot:roll())
    end
    return Rotation()
end

function mrotation.set_yaw(rot, yaw)
    return mrotation.set_yaw_pitch_roll(rot, yaw, rot:pitch(), rot:roll())
end

function mrotation.set_pitch(rot, pitch)
    return mrotation.set_yaw_pitch_roll(rot, rot:yaw(), pitch, rot:roll())
end

function mrotation.set_roll(rot, roll)
    return mrotation.set_yaw_pitch_roll(rot, rot:yaw(), rot:pitch(), roll)
end