--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local InteractionPromptBuilder = require(ReplicatedStorage.shared.world.interaction.InteractionPromptBuilder)
local Item = require(ReplicatedStorage.shared.world.item.Item)
local ItemAttributes = require(ReplicatedStorage.shared.world.item.ItemAttributes)
--local ItemFactory = require(ReplicatedStorage.shared.world.item.ItemFactory)

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

		--[[local itemId = inst.Name
		local itemFactory = ItemFactory.getItemFactory(inst.Name)
		if itemFactory then
			ItemService.registerItem(itemId, itemFactory:create())
		end]]

		local itemTag = "Item" .. inst.Name
		inst:AddTag(itemTag)

		ItemService.registerItem(inst.Name, Item.fromTool(inst))

		CollectionService:GetInstanceAddedSignal(itemTag):Connect(function(taggedInst)
			if not taggedInst:IsA("Tool") then
				return
			end

			local handle = (taggedInst:FindFirstChild("Handle") or taggedInst:FindFirstChild("handle")) :: BasePart?
			if not handle then
				return
			end

			local getPickupAtt = taggedInst:FindFirstChild("PickupTrigger", true) :: Attachment?
			local prompt = InteractionPromptBuilder.new()
				:withPrimaryInteractionKey()
				:withOmniDir(true)
				:withActivationDistance(7)
				:withTitleKey(`ui.prompt.take`)
				:withSubtitleKey(`{taggedInst:GetAttribute(ItemAttributes.NAME_KEY) :: string? or taggedInst.Name}`)
				:create(getPickupAtt and getPickupAtt.Parent :: BasePart or handle, ExpressionContext.new({}), getPickupAtt)

			if not taggedInst:IsDescendantOf(workspace) then
				prompt:setServerVisible(false)
			end

			--

			handle.CanTouch = false
			local touchInterest = handle:FindFirstChildOfClass("TouchTransmitter")
			if touchInterest then
				touchInterest:Destroy()
			end

			--

			local ancestryChangedConn: RBXScriptConnection?
			local promptTriggeredConn: RBXScriptConnection?
			local destroyedConn: RBXScriptConnection?

			local function destroy(): ()
				print("Destroying...")

				if ancestryChangedConn then
					ancestryChangedConn:Disconnect()
					ancestryChangedConn = nil :: any
				end

				if promptTriggeredConn then
					promptTriggeredConn:Disconnect()
					promptTriggeredConn = nil :: any
				end

				if destroyedConn then
					destroyedConn:Disconnect()
					destroyedConn = nil
				end

				prompt:destroy()
				taggedInst = nil :: any
				prompt = nil :: any
			end

			ancestryChangedConn = taggedInst.AncestryChanged:Connect(function(_, parent)
				if not taggedInst:IsDescendantOf(game) then
					destroy()
					return
				end

				if not taggedInst:IsDescendantOf(workspace) then
					prompt:setServerVisible(false)
					return
				end

				if Players:GetPlayerFromCharacter(taggedInst.Parent :: Model) then
					prompt:setServerVisible(false)
					return
				end

				prompt:setServerVisible(true)
			end)

			promptTriggeredConn = prompt:getTriggeredEvent():Connect(function(player)
				taggedInst.Parent = player.Backpack
			end)

			destroyedConn = taggedInst.Destroying:Once(destroy)
		end)
	end
end

--

function ItemService._getToolsFolder(): Folder?
	-- NOTES: This file is in `shared` yet accesses ServerStorage. Why.
	-- Fix this later on. If we even call this from the client anyway.
	return TOOLS_FOLDER_PARENT:FindFirstChild(TOOLS_FOLDER_NAME) :: Folder?
end

return ItemService