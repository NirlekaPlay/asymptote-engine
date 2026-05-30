--!strict

--[=[
	Accessing memory stores on a local build throws an error.
	This is meant to keep things running normally even if its local.
]=]
local function GetSafeMemoryStore(): MemoryStoreService
	local MemoryStoreService = game:GetService("MemoryStoreService")

	local success = pcall(function()
		MemoryStoreService:GetHashMap("TestConnection")
	end)
	
	if success then
		return MemoryStoreService
	end

	local MockHashMap = {}
	MockHashMap.__index = MockHashMap
	function MockHashMap.new() return setmetatable({_storage = {}}, MockHashMap) end
	function MockHashMap:GetAsync(k) return self._storage[k] end
	function MockHashMap:SetAsync(k, v) self._storage[k] = v end
	function MockHashMap:RemoveAsync(k) self._storage[k] = nil end

	local MockMemoryStoreService = { _maps = {} }
	function MockMemoryStoreService:GetHashMap(name)
		if not self._maps[name] then self._maps[name] = MockHashMap.new() end
		return self._maps[name]
	end

	warn("MemoryStoreService failed. Using local Mock instead.")
	return MockMemoryStoreService :: any
end

return GetSafeMemoryStore