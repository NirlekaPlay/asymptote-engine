--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IntegerArgumentType = require(ReplicatedStorage.shared.commands.arguments.IntegerArgumentType)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)
local FriendlyByteBuf = require(ReplicatedStorage.shared.network.FriendlyByteBuf)

type FriendlyByteBuf = FriendlyByteBuf.FriendlyByteBuf

--[=[
	@class IntegerArgumentInfo
]=]
local IntegerArgumentInfo = {}
IntegerArgumentInfo.type = IntegerArgumentType

function IntegerArgumentInfo.serializeToTableFromInstance(argumentType: IntegerArgumentType.IntegerArgumentType): any
	return { type = "int", min = argumentType.minimum, max = argumentType.maximum }
end

function IntegerArgumentInfo.deserializeFromTable(serialized: any): SingletonArgumentInfo.Template
	local template: SingletonArgumentInfo.Template = {
		instantiate = function(self)
			return IntegerArgumentType.integer(serialized.min, serialized.max) :: any
		end
	}
	return template
end

function IntegerArgumentInfo.serializeToNetwork(buf: FriendlyByteBuf, argumentType: IntegerArgumentType.IntegerArgumentType): ()
	local flags = 0
	if argumentType.minimum then flags = bit32.bor(flags, 1) end
	if argumentType.maximum then flags = bit32.bor(flags, 2) end

	buf:writeByte(flags)
	if argumentType.minimum then buf:writeVarInt(argumentType.minimum) end
	if argumentType.maximum then buf:writeVarInt(argumentType.maximum) end
end

function IntegerArgumentInfo.deserializeFromNetwork(buf: FriendlyByteBuf): SingletonArgumentInfo.Template
	local flags = buf:readByte()
	local min, max
	if bit32.band(flags, 1) ~= 0 then min = buf:readVarInt() end
	if bit32.band(flags, 2) ~= 0 then max = buf:readVarInt() end

	return {
		instantiate = function()
			return IntegerArgumentType.integer(min, max) :: any
		end
	}
end

return IntegerArgumentInfo