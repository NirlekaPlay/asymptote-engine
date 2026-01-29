--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AttributeHolder = require(ReplicatedStorage.shared.world.attributes.AttributeHolder)

export type Item = {
	getTool: Tool,
	getAttributeHolder: (self: Item) -> AttributeHolder.AttributeHolder
}

return nil