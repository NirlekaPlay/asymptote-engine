--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.SingletonArgumentInfo)

--[=[
	@class EntityArgumentInfo
]=]
local EntityArgumentInfo = {}
EntityArgumentInfo.type = EntityArgument

function EntityArgumentInfo.serializeToTableFromInstance(argumentType: EntityArgument.EntityArgument): any
	return { type = "entity" }
end

function EntityArgumentInfo.deserializeFromTable(serialized: any): SingletonArgumentInfo.Template
	local template: SingletonArgumentInfo.Template = {
		instantiate = function(self)
			return EntityArgument.entities()
		end
	}
	return template
end

return EntityArgumentInfo