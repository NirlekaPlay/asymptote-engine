--!strict
--!native

local bit32_rshift = bit32.rshift

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
	local c = self.count + 1
	self.count = c
	nodes[c] = node -- Manual insert
	
	-- "Sift Up"
	while c > 1 do
		local p = bit32_rshift(c, 1) -- p = floor(c / 2)
		local nodeC = nodes[c]
		local nodeP = nodes[p]
		
		if nodeC.f < nodeP.f then
			nodes[c], nodes[p] = nodeP, nodeC
			c = p
		else
			break
		end
	end
end

function Heap.pop(self: Heap): Node?
	local count = self.count
	if count == 0 then return nil end
	
	local nodes = self.nodes
	local root = nodes[1]
	
	-- Move last to first
	nodes[1] = nodes[count]
	nodes[count] = nil -- Manual remove
	count -= 1
	self.count = count
	
	local p = 1

	-- "Sift Down"
	while true do
		local c = p * 2 -- Left child
		if c > count then break end
		
		local right = c + 1
		-- Pick the smaller child
		if right <= count and nodes[right].f < nodes[c].f then 
			c = right
		end
		
		local nodeC = nodes[c]
		local nodeP = nodes[p]
		
		if nodeC.f < nodeP.f then
			nodes[c], nodes[p] = nodeP, nodeC
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