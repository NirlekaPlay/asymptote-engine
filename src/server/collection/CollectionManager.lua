--!strict

local CollectionService = game:GetService("CollectionService")
local CollectionTagTypes = require(script.Parent.CollectionTagTypes)

--[=[
	@class CollectionManager
]=]
local CollectionManager = {}

function CollectionManager.mapTaggedInstances<T>(tagType: CollectionTagTypes.TagType<T>, callback: (T) -> ()): ()
	local taggedInstances = CollectionService:GetTagged(tagType.tagName)

	for _, taggedInst in pairs(taggedInstances) do
		if not tagType.predicate(taggedInst) then
			continue
		end

		callback(taggedInst)
	end
end

function CollectionManager.mapOnTaggedInstancesAdded<T>(tagType: CollectionTagTypes.TagType<T>, callback: (T) -> ()): ()
	-- Stated in the documentation:
	-- 'Subsequent calls to this method with the same tag return the same signal object.'
	-- So we don't have to worry about connection cleanup hell.
	CollectionService:GetInstanceAddedSignal(tagType.tagName):Connect(function(taggedInst)
		if not tagType.predicate(taggedInst) then
			return
		end

		callback(taggedInst)
	end)
end

return CollectionManager