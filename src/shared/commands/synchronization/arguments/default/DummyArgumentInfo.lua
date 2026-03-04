--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)
local FriendlyByteBuf = require(ReplicatedStorage.shared.network.FriendlyByteBuf)

type FriendlyByteBuf = FriendlyByteBuf.FriendlyByteBuf

--[=[
	@class DummyArgumentInfo
]=]
local DummyArgumentInfo = {}
DummyArgumentInfo.type = {}

function DummyArgumentInfo.serializeToTableFromInstance(argumentType: ): any
	return {}
end

function DummyArgumentInfo.deserializeFromTable(serialized: any): SingletonArgumentInfo.Template
	local template: SingletonArgumentInfo.Template = {
		instantiate = function(self)
			return {}
		end
	}
	return template
end

function DummyArgumentInfo.serializeToNetwork(buf: FriendlyByteBuf, argumentType: ): ()
	return
end

function DummyArgumentInfo.deserializeFromNetwork(buf: FriendlyByteBuf): SingletonArgumentInfo.Template
	return {
		instantiate = function()
			return IntegerArgumentType.integer(min, max) :: any
		end
	}
end

return DummyArgumentInfo