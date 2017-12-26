--Functions that already exist but we need them by this time.
function string.split(s, separator_pattern, keep_empty, max_splits)
    local result = {}
    local pattern = "(.-)" .. separator_pattern .. "()"
    local count = 0
    local final_match_end_index = 0
    
    for part, end_index in string.gmatch(s, pattern) do
    	final_match_end_index = end_index
    	if keep_empty or part ~= "" then
	        count = count + 1
	        result[count] = part
	        if count == max_splits then break end
        end
	end
	
    local remainder = string.sub(s, final_match_end_index)
    result[count + 1] = (keep_empty or remainder ~= "") and remainder or nil
    return result
end

function string.begins(s, beginning)
	if s and beginning then
		return s:sub(1, #beginning) == beginning
	end
	return false
end

function string.ends(s, ending)
	if s and ending then
		return #ending == 0 or s:sub(-(#ending)) == ending
	end
	return false
end

function table.index_of(v, e)
	for index, value in ipairs(v) do
		if value == e then
			return index
		end
	end
	return -1
end

function table.contains(v, e)
	for _, value in pairs(v) do
		if value == e then
			return true
		end
	end
	return false
end

function clone(o)
	local res = {}
	for k, v in pairs(o) do
		res[k] = v
	end
	setmetatable(res, getmetatable(o))
	return res
end

function deep_clone(o)
	if type(o) == "userdata" then
		return o
	end
	local res = {}
	setmetatable(res, getmetatable(o))
	for k, v in pairs(o) do
		if type(v) == "table" then
			res[k] = deep_clone(v)
		else
			res[k] = v
		end
	end
	return res
end

BLT.__everyclass = {}
BLT.__overrides = {}

--The game will override it eventually, only minus is that __everyclass won't have blt classes so get them using 'BLT.__overrides'
function class(...)
	local super = (...)
	if select("#", ...) >= 1 and super == nil then
		error("trying to inherit from nil", 2)
	end

	local class_table = {}

	if __everyclass then
		table.insert(BLT.__everyclass, class_table)
	end

	class_table.super = BLT.__overrides[super] or super
	class_table.__index = class_table
	class_table.__module__ = getfenv(2)

	setmetatable(class_table, BLT.__overrides[super] or super)

	function class_table.new(klass, ...)
		local object = {}
		setmetatable(object, BLT.__overrides[class_table] or class_table)

		if object.init then
			return object, object:init(...)
		end
		return object
	end

	return class_table
end