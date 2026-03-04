--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JsonArgumentType = require(ReplicatedStorage.shared.commands.arguments.json.JsonArgumentType)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)
local FriendlyByteBuf = require(ReplicatedStorage.shared.network.FriendlyByteBuf)

--[=[
	@class JsonArgumentInfo
]=]
local JsonArgumentInfo = {}
JsonArgumentInfo.type = JsonArgumentType

local TYPE_TO_ID = {
	[JsonArgumentType.JsonType.JSON_OBJECT] = 0,
	[JsonArgumentType.JsonType.JSON_ARRAY] = 1,
}

local ID_TO_TYPE = {
	[0] = JsonArgumentType.JsonType.JSON_OBJECT,
	[1] = JsonArgumentType.JsonType.JSON_ARRAY,
}

function JsonArgumentInfo.serializeToTableFromInstance(argumentType: JsonArgumentType.JsonArgumentType): any
	return { type = "json", jsonType = argumentType.jsonType }
end

function JsonArgumentInfo.deserializeFromTable(serialized: any): SingletonArgumentInfo.Template
	return {
		instantiate = function()
			return if serialized.jsonType == JsonArgumentType.JsonType.JSON_ARRAY 
				then JsonArgumentType.jsonArray() :: any
				else JsonArgumentType.jsonObject() :: any
		end
	}
end

function JsonArgumentInfo.serializeToNetwork(buf: FriendlyByteBuf.FriendlyByteBuf, argumentType: JsonArgumentType.JsonArgumentType): ()
	buf:writeVarInt(TYPE_TO_ID[argumentType.jsonType])
end

function JsonArgumentInfo.deserializeFromNetwork(buf: FriendlyByteBuf.FriendlyByteBuf): SingletonArgumentInfo.Template
	local id = buf:readVarInt()
	local jsonType = ID_TO_TYPE[id]
	
	return {
		instantiate = function()
			return if jsonType == JsonArgumentType.JsonType.JSON_ARRAY 
				then JsonArgumentType.jsonArray() :: any
				else JsonArgumentType.jsonObject() :: any
		end
	}
end

return JsonArgumentInfo