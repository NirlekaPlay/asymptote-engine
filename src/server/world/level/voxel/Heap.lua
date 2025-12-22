--!strict

local insert = table.insert
local remove = table.remove
local floor = math.floor

--[=[
	@class Heap

	A Luau implementation of a [Min-Heap](https://www.geeksforgeeks.org/dsa/introduction-to-min-heap-data-structure/).
	Specifically designed for A* pathfinding.
]=]
local Heap = {}
Heap.__index = Heap

export type Heap = typeof(setmetatable({} :: {
	nodes: { Node },
	count: number
}, Heap))

export type Node = {
	x: number, -- Vector3 axes
	y: number,
	z: number,
	--
	g: number,
	f: number
}

function Heap.new(): Heap
	return setmetatable({
		nodes = {},
		count = 0
	}, Heap)
end

function Heap.push(self: Heap, node: Node)
	local nodes = self.nodes
	insert(nodes, node)
	self.count += 1
	local c = self.count
	
	-- "Sift Up"
	while c > 1 do
		local p = floor(c / 2)
		if nodes[c].f < nodes[p].f then
			nodes[c], nodes[p] = nodes[p], nodes[c]
			c = p
		else
			break
		end
	end
end

function Heap.pop(self: Heap): Node?
	local nodes = self.nodes
	local count = self.count
	if count == 0 then return nil end
	
	local root = nodes[1]
	nodes[1] = nodes[count]
	remove(nodes, count)
	self.count -= 1
	
	local p = 1
	local newCount = count - 1
	
	-- "Sift Down"
	while true do
		local c = p * 2
		if c > newCount then break end
		
		-- Pick the smaller child
		if c + 1 <= newCount and nodes[c+1].f < nodes[c].f then 
			c = c + 1
		end
		
		if nodes[c].f < nodes[p].f then
			nodes[c], nodes[p] = nodes[p], nodes[c]
			p = c
		else
			break
		end
	end

	return root
end

function Heap.size(self: Heap): number
	return self.count
end

function Heap.isEmpty(self: Heap): boolean
	return self.count == 0
end

return Heap