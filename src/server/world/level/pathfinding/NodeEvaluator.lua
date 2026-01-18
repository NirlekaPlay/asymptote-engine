--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Door = require(ServerScriptService.server.world.level.clutter.props.Door)

--[=[
	@class NodeEvaluator
]=]
local NodeEvaluator = {}
NodeEvaluator.__index = NodeEvaluator

export type NodeEvaluator = typeof(setmetatable({} :: {
	
}, NodeEvaluator))

function NodeEvaluator.new(
): NodeEvaluator
	return setmetatable({
	}, NodeEvaluator)
end

function NodeEvaluator.getDoorsInRegion(self: NodeEvaluator, cframe: CFrame, size: Vector3): {Door.Door}

end

function NodeEvaluator.canOpenDoors(self: NodeEvaluator): boolean
	return true
end

function NodeEvaluator.canOpenDoor(self: NodeEvaluator, door: Door.Door): boolean
	return true
end

return NodeEvaluator