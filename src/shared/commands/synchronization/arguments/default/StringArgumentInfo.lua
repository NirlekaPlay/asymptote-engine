--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)
local FriendlyByteBuf = require(ReplicatedStorage.shared.network.FriendlyByteBuf)

--[=[
	@class StringArgumentInfo
]=]
local StringArgumentInfo = {}
StringArgumentInfo.type = StringArgumentType

local STRING_TYPES_TO_METHODS = {
	[StringArgumentType.StringType.GREEDY_PHRASE] = StringArgumentType.greedyString,
	[StringArgumentType.StringType.QUOTABLE_PHRASE] = StringArgumentType.string,
	[StringArgumentType.StringType.SINGLE_WORD] = StringArgumentType.word
}

local TYPE_TO_ID = {
	[StringArgumentType.StringType.SINGLE_WORD] = 0,
	[StringArgumentType.StringType.QUOTABLE_PHRASE] = 1,
	[StringArgumentType.StringType.GREEDY_PHRASE] = 2
}

local ID_TO_TYPE = {
	[0] = StringArgumentType.StringType.SINGLE_WORD,
	[1] = StringArgumentType.StringType.QUOTABLE_PHRASE,
	[2] = StringArgumentType.StringType.GREEDY_PHRASE
}

function StringArgumentInfo.serializeToTableFromInstance(argumentType: StringArgumentType.StringArgumentType): any
	return { type = "str", strType = argumentType.stringType }
end

function StringArgumentInfo.deserializeFromTable(serialized: any): SingletonArgumentInfo.Template
	local template: SingletonArgumentInfo.Template = {
		instantiate = function(self)
			return STRING_TYPES_TO_METHODS[serialized.strType]() :: any
		end
	}
	return template
end

function StringArgumentInfo.serializeToNetwork(buf: FriendlyByteBuf.FriendlyByteBuf, argumentType: StringArgumentType.StringArgumentType): ()
	buf:writeVarInt(TYPE_TO_ID[argumentType.stringType])
end

function StringArgumentInfo.deserializeFromNetwork(buf: FriendlyByteBuf.FriendlyByteBuf): SingletonArgumentInfo.Template
	local id = buf:readVarInt()
	local strType = ID_TO_TYPE[id]
	
	return {
		instantiate = function()
			return STRING_TYPES_TO_METHODS[strType]() :: any
		end
	}
end

return StringArgumentInfo