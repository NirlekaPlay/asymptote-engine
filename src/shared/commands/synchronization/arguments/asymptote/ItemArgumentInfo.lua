--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.ItemArgument)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)
local FriendlyByteBuf = require(ReplicatedStorage.shared.network.FriendlyByteBuf)

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

--

function ItemArgumentInfo.serializeToNetwork(buf: FriendlyByteBuf.FriendlyByteBuf, argumentType: ItemArgument.ItemArgument): ()
	return
end

function ItemArgumentInfo.deserializeFromNetwork(buf: FriendlyByteBuf.FriendlyByteBuf): SingletonArgumentInfo.Template
	return {
		instantiate = function()
			return ItemArgument.item()
		end
	}
end

return ItemArgumentInfo