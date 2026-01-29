--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Item = require(ReplicatedStorage.shared.world.item.Item)
local ItemAttributes = require(ReplicatedStorage.shared.world.item.ItemAttributes)
local ItemFactory = require(ReplicatedStorage.shared.world.item.ItemFactory)

local TOOLS_FOLDER_PARENT = ServerStorage
local TOOLS_FOLDER_NAME = "Tools"

local itemRegistry: { [string]: Item.Item } = {}

--[=[
	@class ItemService
]=]
local ItemService = {}

function ItemService.registerItem(itemName: string, item: Item.Item): ()
	itemRegistry[itemName] = item
end

function ItemService.getItem(itemName: string): Item.Item?
	return itemRegistry[itemName]
end

function ItemService.getItemLocalizedStringName(itemId: string): string
	local fetchItem = ItemService.getItem(itemId)
	if fetchItem then
		local nameKey = fetchItem:getAttributeHolder():getAttribute(ItemAttributes.NAME_KEY)
		if nameKey then
			return nameKey
		end
	end


	return itemId
end

--

function ItemService.register(): ()
	local toolsFolder = ItemService._getToolsFolder()
	if not toolsFolder then
		warn(`Cannot register items: '{TOOLS_FOLDER_NAME}' is missing in '{TOOLS_FOLDER_PARENT:GetFullName()}'`)
		return
	end

	for _, inst in toolsFolder:GetChildren() do
		if not inst:IsA("Tool") then
			continue
		end

		local itemId = inst.Name
		local itemFactory = ItemFactory.getItemFactory(inst.Name)
		if itemFactory then
			ItemService.registerItem(itemId, itemFactory:create())
		end
	end
end

--

function ItemService._getToolsFolder(): Folder?
	-- NOTES: This file is in `shared` yet accesses ServerStorage. Why.
	-- Fix this later on. If we even call this from the client anyway.
	return TOOLS_FOLDER_PARENT:FindFirstChild(TOOLS_FOLDER_NAME) :: Folder?
end

return ItemService