_G.Hooks = Hooks or {}
Hooks._registered_hooks = Hooks._registered_hooks or {}
Hooks._prehooks = Hooks._prehooks or {}
Hooks._posthooks = Hooks._posthooks or {}

--[[
	Hooks:Register(key)
		Registers a hook so that functions can be added to it, and later called
	key, Unique identifier for the hook, so that hooked functions can be added to it
]]
function Hooks:RegisterHook(key)
	self._registered_hooks[key] = self._registered_hooks[key] or {}
	return key
end

--[[
	Hooks:Register(key)
		Functionaly the same as Hooks:RegisterHook
]]
function Hooks:Register(key)
	return self:RegisterHook(key)
end

--[[
	Hooks:AddHook(key, id, func)
		Adds a function call to a hook, so that it will be called when the hook is
	key, 	The unique identifier of the hook to be called on
	id, 	A unique identifier for this specific function call
	func, 	The function to call with the hook
]]
function Hooks:AddHook(key, id, func)
	if type(func) ~= "function" then
		BLT:LogF(LogLevel.ERROR, "BLTHook", "Hook '%s' is not a function.", tostring(id))
		return
	end

	if self._registered_hooks[key] == nil then
		self._registered_hooks[key] = {}
	else
		for _, v in pairs(self._registered_hooks[key]) do
			if v.id == id then
				return false
			end
		end
	end

	table.insert(self._registered_hooks[key], { id = id, func = func })
end

--[[
	Hooks:Add(key, id, func)
		Functionaly the same as Hooks:AddHook
]]
function Hooks:Add(key, id, func)
	self:AddHook(key, id, func)
end

--[[
	Hooks:UnregisterHook(key)
		Removes a hook, so that it will not call any functions
	key, The unique identifier of the hook to unregister
]]
function Hooks:UnregisterHook(key)
	self._registered_hooks[key] = nil
end

--[[
	Hooks:Unregister(key)
		Functionaly the same as Hooks:UnregisterHook
]]
function Hooks:Unregister(key)
	self:UnregisterHook(key)
end

function Hooks:RemoveHook(key, id)
	local hooks = self._registered_hooks[key]
	if hooks then
		for i, v in pairs(hooks) do
			if v.id == id then
				table.remove(hooks, i)
				break
			end
		end
	end
end

--[[
	Hooks:Remove(id)
		Removes a hooked function call with the specified id to prevent it from being called
	id, Removes the function call and prevents it from being called
]]
function Hooks:Remove(id)
	for _, hooks in pairs(self._registered_hooks) do
		for i, v in pairs(hooks) do
			if v.id == id then
				table.remove(hooks, i)

				-- NOTE: While it's supposed to be globally unique, this is not guaranteed, so
				-- remove all matching hooks.
				break
			end
		end
	end
end

--[[
	Hooks:Call(key, ...)
			Calls a specified hook, and all of its hooked functions
	key,	The unique identifier of the hook to call its hooked functions
	args,	The arguments to pass to the hooked functions
]]
function Hooks:Call(key, ...)
	if not self._registered_hooks[key] then
		return
	end

	for _, v in ipairs(self._registered_hooks[key]) do
		v.func(...)
	end
end

--[[
	Hooks:ReturnCall(key, ...)
		Calls a specified hook, and returns the first non-nil value returned by a hooked function
	key, 		The unique identifier of the hook to call its hooked functions
	args, 		The arguments to pass to the hooked functions
	returns, 	The first non-nil value returned by a hooked function
]]
function Hooks:ReturnCall(key, ...)
	if not self._registered_hooks[key] then
		return
	end

	for _, v in ipairs(self._registered_hooks[key]) do
		local ret = { v.func(...) }
		if ret[1] ~= nil then
			return unpack(ret)
		end
	end
end

--[[
	Hooks:PreHook(object, func, id, pre_call)
		Automatically hooks a function to be called before the specified function on a specified object
	object, 	The object for the hooked function to be called on
	func, 		The name of the function (as a string) on the object for the hooked call to be ran before
	id, 		The unique identifier for this prehook
	pre_call, 	The function to be called before the func on object
]]
function Hooks:PreHook(object, func, id, pre_call)
	if not object or type(pre_call) ~= "function" then
		self:_PrePostHookError(func, id)
		return
	end

	if self._prehooks[object] == nil then
		self._prehooks[object] = {}
	end

	if self._prehooks[object][func] == nil then
		self._prehooks[object][func] = {
			original = object[func],
			overrides = {}
		}

		object[func] = function(...)
			local hooked_func = self._prehooks[object][func]
			local r, _r

			for k, v in ipairs(hooked_func.overrides) do
				_r = v.func(...)
				if _r then
					r = _r
				end
			end

			_r = hooked_func.original(...)
			if _r then
				r = _r
			end

			return r
		end
	else
		for k, v in pairs(self._prehooks[object][func].overrides) do
			if v.id == id then
				return
			end
		end
	end

	table.insert(self._prehooks[object][func].overrides, { id = id, func = pre_call })
end

function Hooks:Pre(...)
	self:PreHook(...)
end

--[[
	Hooks:RemovePreHook(id)
		Removes the prehook with id, and prevents it from being run
	id, The unique identifier of the prehook to remove
]]
function Hooks:RemovePreHook(id)
	for object_i, object in pairs(self._prehooks) do
		for func_i, func in pairs(object) do
			for override_i, override in pairs(func.overrides) do
				if override.id == id then
					table.remove(func.overrides, override_i)
				end
			end
		end
	end
end

--[[
	Hooks:PostHook(object, func, id, post_call)
		Automatically hooks a function to be called after the specified function on a specified object
	object, 	The object for the hooked function to be called on
	func, 		The name of the function (as a string) on the object for the hooked call to be ran after
	id, 		The unique identifier for this posthook
	post_call, 	The function to be called after the func on object
]]
function Hooks:PostHook(object, func, id, post_call)
	if not object or type(post_call) ~= "function" then
		self:_PrePostHookError(func, id)
		return
	end

	if self._posthooks[object] == nil then
		self._posthooks[object] = {}
	end

	if self._posthooks[object][func] == nil then
		self._posthooks[object][func] = {
			original = object[func],
			overrides = {}
		}

		object[func] = function(...)
			local hooked_func = self._posthooks[object][func]
			local r, _r

			_r = hooked_func.original(...)
			if _r then
				r = _r
			end

			for k, v in ipairs(hooked_func.overrides) do
				_r = v.func(...)
				if _r then
					r = _r
				end
			end

			return r
		end
	else
		for k, v in pairs(self._posthooks[object][func].overrides) do
			if v.id == id then
				return
			end
		end
	end

	table.insert(self._posthooks[object][func].overrides, { id = id, func = post_call })
end

function Hooks:Post(...)
	self:PostHook(...)
end

--[[
	Hooks:RemovePostHook(id)
		Removes the posthook with id, and prevents it from being run
	id, The unique identifier of the posthook to remove
]]
function Hooks:RemovePostHook(id)
	for object_i, object in pairs(self._posthooks) do
		for func_i, func in pairs(object) do
			for override_i, override in pairs(func.overrides) do
				if override.id == id then
					table.remove(func.overrides, override_i)
				end
			end
		end
	end
end

function Hooks:_PrePostHookError(func, id)
	BLT:LogF(LogLevel.ERROR, "BLTHook", "Could not hook function '%s' (%s).", tostring(func), tostring(id))
end

--TODO: Write what the functions do

function Hooks:RemovePostHookWithObject(object, id)
	local hooks = self._posthooks[object]
	if not hooks then
		BLT:LogF(LogLevel.ERROR, "BLTHook", "No post hooks for object '%s' while trying to remove id '%s'.",
			tostring(object), tostring(id))
		return
	end

	for func_i, func in pairs(hooks) do
		for override_i, override in pairs(func.overrides) do
			if override.id == id then
				table.remove(func.overrides, override_i)
			end
		end
	end
end

function Hooks:RemovePreHookWithObject(object, id)
	local hooks = self._prehooks[object]
	if not hooks then
		BLT:LogF(LogLevel.ERROR, "BLTHook", "No pre hooks for object '%s' while trying to remove id '%s'.",
			tostring(object), tostring(id))
		return
	end

	for func_i, func in pairs(hooks) do
		for override_i, override in pairs(func.overrides) do
			if override.id == id then
				table.remove(func.overrides, override_i)
			end
		end
	end
end
