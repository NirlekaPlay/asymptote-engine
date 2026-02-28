--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BooleanArgumentType = require(ReplicatedStorage.shared.commands.arguments.BooleanArgumentType)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.SingletonArgumentInfo)

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

return BooleanArgumentInfo