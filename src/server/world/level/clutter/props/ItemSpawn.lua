--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Prop = require(ServerScriptService.server.world.level.clutter.props.Prop)

--[=[
	@class ItemSpawn
]=]
local ItemSpawn = {}

export type ItemSpawn = Prop.Prop & typeof(setmetatable({} :: {
}, ItemSpawn))

function ItemSpawn.new(): ItemSpawn
	return setmetatable({}, ItemSpawn) :: ItemSpawn
end

function ItemSpawn.createFromPlaceholder(placeholder: BasePart, model: Model?): ItemSpawn
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

	local newItemSpawn = ItemSpawn.new()

	local itemToolClone = itemTool:Clone()
	itemToolClone:PivotTo(placeholder.CFrame)

	itemToolClone.Parent = workspace

	return newItemSpawn
end

function ItemSpawn.update(self: ItemSpawn, deltaTime: number): ()
	return
end

function ItemSpawn.onLevelRestart(self: ItemSpawn): ()
	
end

return ItemSpawn