--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BooleanArgumentType = require(ReplicatedStorage.shared.commands.arguments.BooleanArgumentType)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)
local FriendlyByteBuf = require(ReplicatedStorage.shared.network.FriendlyByteBuf)

--[=[
	@class BooleanArgumentInfo
]=]
local BooleanArgumentInfo = {}
BooleanArgumentInfo.type = BooleanArgumentType

function BooleanArgumentInfo.serializeToTableFromInstance(argumentType: BooleanArgumentType.BooleanArgumentType): any
	return { type = "bool" }
end

function BooleanArgumentInfo.deserializeFromTable(serialized: any): SingletonArgumentInfo.Template
	local template: SingletonArgumentInfo.Template = {
		instantiate = function(self)
			return BooleanArgumentType.bool()
		end
	}
	return template
end

--

function BooleanArgumentInfo.serializeToNetwork(buf: FriendlyByteBuf.FriendlyByteBuf, argumentType: BooleanArgumentType.BooleanArgumentType): ()
	return
end

function BooleanArgumentInfo.deserializeFromNetwork(buf: FriendlyByteBuf.FriendlyByteBuf): SingletonArgumentInfo.Template
	return {
		instantiate = function()
			return BooleanArgumentType.bool()
		end
	}
end

return BooleanArgumentInfo