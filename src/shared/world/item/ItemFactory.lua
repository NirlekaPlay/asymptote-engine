--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Item = require(ReplicatedStorage.shared.world.item.Item)

--[=[
	@class ItemFactory
]=]
local ItemFactory = {}

export type ItemFactory<T> = {
	create: (self: ItemFactory<T>) -> T & Item.Item
}

local registry: { [string]: ItemFactory<any> } = {}

function ItemFactory.getItemFactory(itemId: string): ItemFactory<any>?
	return registry[itemId]
end

function ItemFactory.register<T>(itemId: string, item: T): ()
	registry[itemId] = {
		create = function(self: ItemFactory<T>): T
			return item
		end
	}
end

return ItemFactory