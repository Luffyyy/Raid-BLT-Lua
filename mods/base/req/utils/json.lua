
_G.json = {}

function json.decode(data)
	local value = nil
	local passed = pcall(function()
		value = json10.decode(data)
	end)
	return value or {}
end

function json.encode(data)
	return json10.encode(data)
end
