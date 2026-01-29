--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AttributeHolder = require(ReplicatedStorage.shared.world.attributes.AttributeHolder)
local InstanceAttributeHolder = require(ReplicatedStorage.shared.world.attributes.InstanceAttributeHolder)

--[=[
	@class Item
]=]
local Item = {}
Item.__index = Item

export type Item = typeof(setmetatable({} :: {
	tool: Tool,
	attributeHolder: AttributeHolder.AttributeHolder
}, Item))

function Item.fromTool(tool: Tool): Item
	return setmetatable({
		tool = tool,
		attributeHolder = InstanceAttributeHolder.new(tool) :: AttributeHolder.AttributeHolder
	}, Item)
end

function Item.getTool(self: Item): Tool
	return self.tool
end

function Item.getAttributeHolder(self: Item): AttributeHolder.AttributeHolder
	return self.attributeHolder
end

return Item