--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IntegerArgumentType = require(ReplicatedStorage.shared.commands.arguments.IntegerArgumentType)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.SingletonArgumentInfo)

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

return IntegerArgumentInfo