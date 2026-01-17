--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)

local DEBUG_MODE = false
local DEBUG_PART_SIZE = Vector3.new(4, 0.2, 2)
local DEBUG_UNOCCUPIED_COLOR = Color3.new(0, 1, 0)
local DEBUG_OCCUPIED_COLOR = Color3.new(1, 0, 0)

--[=[
	@class Node

	Not to be confused with waypoints, a Node defines what an NPC
	go to. Such as the patrol posts for guards where they go and stay there
	for an amount of time, and go to another patrol post
]=]
local Node = {}
Node.__index = Node

export type Node = typeof(setmetatable({} :: {
	cframe: CFrame,
	occupied: boolean,
	cachedBlockPos: Vector3?,
	_debugPart: BasePart?
}, Node))

function Node.new(cframe: CFrame, doDebug: boolean?): Node
	return setmetatable({
		cframe = cframe,
		occupied = false,
		cachedBlockPos = nil :: Vector3?,
		_debugPart = (DEBUG_MODE and doDebug) and Draw.box(cframe, DEBUG_PART_SIZE, DEBUG_UNOCCUPIED_COLOR) or nil
	}, Node)
end

function Node.fromPart(part: BasePart, doDebug: boolean?): Node
	return Node.new(part.CFrame, doDebug)
end

--

function Node.getLookVector(self: Node): Vector3
	return self.cframe.LookVector
end

function Node.getPosition(self: Node): Vector3
	return self.cframe.Position
end

function Node.getBlockPosition(self: Node): Vector3
	if self.cachedBlockPos then
		return self.cachedBlockPos
	end

	local pos = self.cframe.Position
	self.cachedBlockPos = Vector3.new(
		math.floor(pos.X),
		math.floor(pos.Y),
		math.floor(pos.Z)
	)

	return self.cachedBlockPos
end

function Node.isOccupied(self: Node): boolean
	return self.occupied
end

function Node.occupy(self: Node): ()
	self.occupied = true
	if DEBUG_MODE and self._debugPart then
		(self._debugPart :: BasePart).Transparency = 1
		(self._debugPart :: any).BoxHandleAdornment.Color3 = DEBUG_OCCUPIED_COLOR
	end
end

function Node.vacate(self: Node): ()
	self.occupied = false
	if DEBUG_MODE and self._debugPart then
		(self._debugPart :: BasePart).Transparency = 1
		(self._debugPart :: any).BoxHandleAdornment.Color3 = DEBUG_UNOCCUPIED_COLOR
	end
end

function Node.__tostring(self: Node): string
	local pos = self.cframe.Position
	local x, y, z = pos.X, pos.Y, pos.Z
	return string.format(
		"Node{occupied: %s; pos: x=%.2f, y=%.2f, z=%.2f}",
		tostring(self.occupied), x, y, z
	)
end

return Node