--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)
local FriendlyByteBuf = require(ReplicatedStorage.shared.network.FriendlyByteBuf)

--[=[
	@class EntityArgumentInfo
]=]
local EntityArgumentInfo = {}
EntityArgumentInfo.type = EntityArgument

function EntityArgumentInfo.serializeToTableFromInstance(argumentType: EntityArgument.EntityArgument): any
	return { type = "entity" }
end

function EntityArgumentInfo.deserializeFromTable(serialized: any): SingletonArgumentInfo.Template
	local template: SingletonArgumentInfo.Template = {
		instantiate = function(self)
			return EntityArgument.entities()
		end
	}
	return template
end

--

function EntityArgumentInfo.serializeToNetwork(buf: FriendlyByteBuf.FriendlyByteBuf, argumentType: EntityArgument.EntityArgument): ()
	return
end

function EntityArgumentInfo.deserializeFromNetwork(buf: FriendlyByteBuf.FriendlyByteBuf): SingletonArgumentInfo.Template
	return {
		instantiate = function()
			return EntityArgument.entities()
		end
	}
end

return EntityArgumentInfo