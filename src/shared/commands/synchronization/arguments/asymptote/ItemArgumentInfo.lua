--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.ItemArgument)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)

--[=[
	@class ItemArgumentInfo
]=]
local ItemArgumentInfo = {}
ItemArgumentInfo.type = ItemArgument

function ItemArgumentInfo.serializeToTableFromInstance(argumentType: ItemArgument.ItemArgument): any
	return { type = "item" }
end

function ItemArgumentInfo.deserializeFromTable(serialized: any): SingletonArgumentInfo.Template
	local template: SingletonArgumentInfo.Template = {
		instantiate = function(self)
			return ItemArgument.item()
		end
	}
	return template
end

return ItemArgumentInfo