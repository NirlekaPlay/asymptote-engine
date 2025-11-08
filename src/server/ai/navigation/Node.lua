--!strict

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
	occupied: boolean
}, Node))

function Node.new(cframe: CFrame): Node
	return setmetatable({
		cframe = cframe,
		occupied = false
	}, Node)
end

function Node.fromPart(part: BasePart, doDestroy: boolean?): Node
	local newPost = Node.new(part.CFrame)
	if doDestroy then
		part:Destroy()
	end
	return newPost
end

--

function Node.getLookVector(self: Node): Vector3
	return self.cframe.LookVector
end

function Node.getPosition(self: Node): Vector3
	return self.cframe.Position
end

function Node.isOccupied(self: Node): boolean
	return self.occupied
end

function Node.occupy(self: Node): ()
	self.occupied = true
end

function Node.vacate(self: Node): ()
	self.occupied = false
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