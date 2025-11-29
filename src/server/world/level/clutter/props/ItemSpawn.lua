--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local Prop = require(ServerScriptService.server.world.level.clutter.props.Prop)

--[=[
	@class ItemSpawn
]=]
local ItemSpawn = {}
ItemSpawn.__index = ItemSpawn

export type ItemSpawn = Prop.Prop & typeof(setmetatable({} :: {
	itemTool: Tool,
	currentlySpawnedItem: Tool?,
	currentSpawnedItemParentChangedConn: RBXScriptConnection?,
	spawnCFrame: CFrame,
	serverLevel: ServerLevel.ServerLevel
}, ItemSpawn)) 

function ItemSpawn.new(itemTool: Tool, spawnCFrame: CFrame, serverLevel: ServerLevel.ServerLevel): ItemSpawn
	return setmetatable({
		itemTool = itemTool,
		currentlySpawnedItem = nil,
		currentSpawnedItemParentChangedConn = nil,
		spawnCFrame = spawnCFrame,
		serverLevel = serverLevel
	}, ItemSpawn) :: ItemSpawn
end

function ItemSpawn.createFromPlaceholder(placeholder: BasePart, model: Model?, serverLevel: ServerLevel.ServerLevel): ItemSpawn
	local itemName = placeholder:GetAttribute("Item") :: string
	local itemTool = (ServerStorage :: any).Tools:FindFirstChild(itemName) :: Tool?
	if not itemTool then
		error(`Item '{itemTool}' does not exist under ServerStorage.Tools`)
	end

	placeholder.Transparency = 1
	placeholder.CanCollide = false
	placeholder.CanQuery = false
	placeholder.Anchored = true
	placeholder.CanTouch = false
	placeholder.AudioCanCollide = false

	local bottomFaceCFrame = placeholder.CFrame * CFrame.new(0, -placeholder.Size.Y / 2, 0)

	local newItemSpawn = ItemSpawn.new(itemTool, bottomFaceCFrame, serverLevel)
	newItemSpawn:spawnItem()
	return newItemSpawn
end

function ItemSpawn.spawnItem(self: ItemSpawn): ()
	if self.currentlySpawnedItem then
		return
	end

	local itemToolClone = self.itemTool:Clone() :: Tool
	itemToolClone:PivotTo(self.spawnCFrame)

	itemToolClone.Parent = workspace

	self.currentlySpawnedItem = itemToolClone

	self.currentSpawnedItemParentChangedConn = itemToolClone.AncestryChanged:Connect(function()
		if itemToolClone.Parent ~= workspace then
			if self.currentSpawnedItemParentChangedConn then
				self.currentSpawnedItemParentChangedConn:Disconnect()
				self.currentSpawnedItemParentChangedConn = nil
			end

			self.currentlySpawnedItem = nil

			(self.serverLevel :: ServerLevel.ServerLevel):getPersistentInstanceManager():register(itemToolClone)
		end
	end)
end

function ItemSpawn.update(self: ItemSpawn, deltaTime: number): ()
	return
end

function ItemSpawn.onLevelRestart(self: ItemSpawn): ()
	self:spawnItem()
end

return ItemSpawn