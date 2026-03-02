--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)

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

return StringArgumentInfo