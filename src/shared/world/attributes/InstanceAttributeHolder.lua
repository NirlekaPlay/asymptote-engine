--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AttributeHolder = require(ReplicatedStorage.shared.world.attributes.AttributeHolder)

--[=[
	@class InstanceAttributeHolder
]=]
local InstanceAttributeHolder = {}
InstanceAttributeHolder.__index = InstanceAttributeHolder

export type InstanceAttributeHolder = AttributeHolder.AttributeHolder & typeof(setmetatable({} :: {
	instance: Instance
}, InstanceAttributeHolder)) 

function InstanceAttributeHolder.new(inst: Instance): InstanceAttributeHolder 
	return setmetatable({
		instance = inst
	}, InstanceAttributeHolder) :: InstanceAttributeHolder
end

function InstanceAttributeHolder.getAttribute(self: InstanceAttributeHolder, name: string): any
	return self.instance:GetAttribute(name) :: any
end

return InstanceAttributeHolder