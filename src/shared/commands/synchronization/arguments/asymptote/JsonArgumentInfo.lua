--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JsonArgumentType = require(ReplicatedStorage.shared.commands.arguments.json.JsonArgumentType)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)

--[=[
	@class JsonArgumentInfo
]=]
local JsonArgumentInfo = {}
JsonArgumentInfo.type = JsonArgumentType

function JsonArgumentInfo.serializeToTableFromInstance(argumentType: JsonArgumentType.JsonArgumentType): any
	return { type = "json", jsonType = argumentType.jsonType }
end

function JsonArgumentInfo.deserializeFromTable(serialized: any): SingletonArgumentInfo.Template
	local template: SingletonArgumentInfo.Template = {
		instantiate = function(self)
			return if serialized.jsonType == JsonArgumentType.JsonType.JSON_ARRAY then JsonArgumentType.jsonArray() else JsonArgumentType.jsonObject()
		end
	}
	return template
end

return JsonArgumentInfo