--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BooleanArgumentType = require(ReplicatedStorage.shared.commands.arguments.BooleanArgumentType)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.SingletonArgumentInfo)

--[=[
	@class DummyArgumentInfo
]=]
local DummyArgumentInfo = {}
DummyArgumentInfo.type = {}

function DummyArgumentInfo.serializeToTableFromInstance(argumentType: BooleanArgumentType.BooleanArgumentType): any
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

return DummyArgumentInfo