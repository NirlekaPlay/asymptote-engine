--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Heap = require(ServerScriptService.server.world.level.voxel.Heap)

local DEBUG_PATH_NODES = true
local DEBUG_PATH_NODES_SERVER = false -- If this is true, it will create debug parts on the server
local DEBUG_PATH_NODES_FOLDER_NAME = "DebugComputedNodes"
local DEBUG_VOXELS = false -- TURNING THIS ON WILL LIKELY CRASH YOUR POOR PC
local DEFAULT_MATERIAL_ID = 2
local RESOLUTION = 1
local CHUNK_SIZE = 16
local TIME_BUDGET = 0.002 -- 2ms per frame
local PATH_DIR_PERCENTAGE = 1 - 0.30 -- How close of a path's nodes to compute the perceived sound direction

local MATERIALS = {
	[Enum.Material.Air] = 0,
	[Enum.Material.Wood] = 1,
	[Enum.Material.Concrete] = 2,
	[Enum.Material.Metal] = 3,
}

local WEIGHTS = {
	[0] = 1,
	[1] = 15,
	[2] = 100,
	[3] = 150
}

local NEIGHBOR_OFFSETS = {
	Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
	Vector3.new(0, 1, 0), Vector3.new(0, -1, 0),
	Vector3.new(0, 0, 1), Vector3.new(0, 0, -1)
}

--[=[
	@class VoxelWorld

	Implementation of a voxel-based world for calculating
	sound propagation.
]=]
local VoxelWorld = {}
VoxelWorld.__index = VoxelWorld

export type VoxelWorld = typeof(setmetatable({} :: {
	chunks: { [any]: any },
	min: Vector3
}, VoxelWorld))

function VoxelWorld.new(min: Vector3, max: Vector3): VoxelWorld
	local self = setmetatable({}, VoxelWorld)
	self.chunks = {}
	self.min = min
	return self
end

local function snapToGrid(vector: Vector3)
	return Vector3.new(
		math.floor(vector.X / RESOLUTION) * RESOLUTION,
		math.floor(vector.Y / RESOLUTION) * RESOLUTION,
		math.floor(vector.Z / RESOLUTION) * RESOLUTION
	)
end

local function hashPos(x: number, y: number, z: number): number
	return x * 1000000 + y * 1000 + z
end

local function getDirectionFromPath(nodes: {{pos: Vector3, cost: number}}, targetT: number): Vector3
	local maxCostFound = 0
	for _, node in nodes do
		if node.cost > maxCostFound then
			maxCostFound = node.cost
		end
	end
	
	local directionPos = nodes[1].pos  -- fallback to last node
	local closestDiff = math.huge
	
	for _, node in nodes do
		local t = maxCostFound > 0 and (node.cost / maxCostFound) or 0
		local diff = math.abs(t - targetT)
		if diff < closestDiff then
			closestDiff = diff
			directionPos = node.pos
		end
	end
	
	return directionPos
end

local function getFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local newFolder = Instance.new("Folder")
	newFolder.Name = name
	newFolder.Parent = parent

	return newFolder
end

local currentDebugVisualizeComputedNodesThread: thread? = nil
local computedNodesFolder = getFolder(workspace, DEBUG_PATH_NODES_FOLDER_NAME)

local function cancelLastDebugThread(): ()
	if currentDebugVisualizeComputedNodesThread then
		task.cancel(currentDebugVisualizeComputedNodesThread)
		currentDebugVisualizeComputedNodesThread = nil
		computedNodesFolder:ClearAllChildren()
	end
end

local function visualizeComputedNodes(debugNodes: {{pos: Vector3, cost: number}}): ()
	cancelLastDebugThread()

	currentDebugVisualizeComputedNodesThread = task.spawn(function()
		local maxCostFound = 0
		for _, node in debugNodes do
			if node.cost > maxCostFound then
				maxCostFound = node.cost
			end
		end
		
		for _, node in debugNodes do
			local t = maxCostFound > 0 and (node.cost / maxCostFound) or 0
			local color = Color3.new(t, 1 - t, 0)

			local dPart = Draw.box(
				CFrame.new(node.pos),
				Vector3.one * (RESOLUTION * 0.8),
				color
			)

			dPart.Parent = computedNodesFolder
			--task.wait()
		end
	end)
end

function VoxelWorld.getSoundPathAsync(
	self: VoxelWorld,
	startPos: Vector3,
	endPos: Vector3,
	maxCost: number
): (number, Vector3, {{cost: number, pos: Vector3}})
	-- Convert world positions to grid coordinates
	local startSnapped = snapToGrid(startPos)
	local endSnapped = snapToGrid(endPos)
	
	local startV = (startSnapped - self.min) / RESOLUTION
	local endV = (endSnapped - self.min) / RESOLUTION
	
	local startX = math.floor(startV.X)
	local startY = math.floor(startV.Y)
	local startZ = math.floor(startV.Z)
	
	local endX = math.floor(endV.X)
	local endY = math.floor(endV.Y)
	local endZ = math.floor(endV.Z)

	local openList = Heap.new()
	local closedList: { boolean } = {}
	
	local dx = math.abs(endX - startX)
	local dy = math.abs(endY - startY)
	local dz = math.abs(endZ - startZ)
	local initialH = dx + dy + dz

	local closestNode = {x = startX, y = startY, z = startZ, h = initialH}
	
	openList:push({
		x = startX,
		y = startY,
		z = startZ,
		g = 0,
		f = initialH
	})
	
	local debugNodes = {}
	local pathNodes: {{cost: number, pos: Vector3}} = {}

	local startClock = os.clock()
	
	-- We yield instead of crashing the frame
	while not openList:isEmpty() do
		-- Budget check
		if os.clock() - startClock > TIME_BUDGET then
			task.wait()
			startClock = os.clock()
		end

		local current = openList:pop() :: Heap.Node
		local cx, cy, cz = current.x, current.y, current.z

		local worldPos = self.min + Vector3.new(cx, cy, cz) * RESOLUTION
		local tNode = {pos = worldPos, cost = current.g}
		table.insert(pathNodes, tNode)
		
		if DEBUG_PATH_NODES then
			table.insert(debugNodes, tNode) -- TODO: This is just redundant as fuck.
		end
		
		-- Check if reached goal (within 1 voxel)
		dx = cx - endX
		dy = cy - endY
		dz = cz - endZ
		if dx*dx + dy*dy + dz*dz < 2 then
			if DEBUG_PATH_NODES_SERVER then
				visualizeComputedNodes(debugNodes)
			end
			
			return current.g, getDirectionFromPath(pathNodes, PATH_DIR_PERCENTAGE), debugNodes
		end
		
		-- Use hash for closed list
		local key = hashPos(cx, cy, cz)
		
		if closedList[key] or current.g > maxCost then
			continue
		end
		closedList[key] = true
		
		-- Check all 6 neighbors
		for i = 1, 6 do
			local offset = NEIGHBOR_OFFSETS[i]
			local nx = cx + offset.X
			local ny = cy + offset.Y
			local nz = cz + offset.Z
			
			-- Check if already visited
			local nkey = hashPos(nx, ny, nz)
			if closedList[nkey] then 
				continue 
			end
			
			-- Get material and calculate cost
			local matId = self:getVoxel(nx, ny, nz)
			local stepCost = WEIGHTS[matId] or DEFAULT_MATERIAL_ID
			local g = current.g + stepCost
			
			-- Early termination if over budget
			if g > maxCost then
				continue
			end
			
			-- Calculate heuristic (Manhattan distance)
			dx = math.abs(endX - nx)
			dy = math.abs(endY - ny)
			dz = math.abs(endZ - nz)
			local h = dx + dy + dz

			if h < closestNode.h then
				closestNode = {x = nx, y = ny, z = nz, h = h}
			end
			
			openList:push({
				x = nx,
				y = ny,
				z = nz,
				g = g,
				f = g + h
			})
		end
	end

	cancelLastDebugThread()

	local lastPos = self.min + Vector3.new(closestNode.x, closestNode.y, closestNode.z) * RESOLUTION

	return math.huge, lastPos, {}
end

function VoxelWorld.voxelize(self: VoxelWorld, parent: Instance)
	self.chunks = {}

	local parts: { BasePart } = {}
	for _, descendant in parent:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end

	local processedCount = 0
	local yieldFrequency = 500

	for _, part in parts do
		local cf = part.CFrame
		local size = part.Size
		local halfSize = size / 2

		-- Gets the AABB of the part.
		-- Then for every voxels inside said AABB,
		-- we check if the voxels' center are inside the part
		-- if it is, mark it, with the part's material.
		
		-- Calculate AABB relative to world Min to get grid coordinates
		local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector
		local absSize = Vector3.new(
			math.abs(right.X * size.X) + math.abs(up.X * size.Y) + math.abs(look.X * size.Z),
			math.abs(right.Y * size.X) + math.abs(up.Y * size.Y) + math.abs(look.Y * size.Z),
			math.abs(right.Z * size.X) + math.abs(up.Z * size.Y) + math.abs(look.Z * size.Z)
		)

		-- Grid-space bounds
		local minV = (cf.Position - (absSize / 2) - self.min) / RESOLUTION
		local maxV = (cf.Position + (absSize / 2) - self.min) / RESOLUTION

		local matValue = MATERIALS[part.Material] or DEFAULT_MATERIAL_ID

		-- Iterate through the grid bounds of this part
		for x = math.floor(minV.X), math.ceil(maxV.X) do
			for y = math.floor(minV.Y), math.ceil(maxV.Y) do
				for z = math.floor(minV.Z), math.ceil(maxV.Z) do
					
					-- Precision check: is this voxel center actually inside the part?
					local worldPos = self.min + Vector3.new(x, y, z) * RESOLUTION
					local localPos = cf:PointToObjectSpace(worldPos)
					
					if math.abs(localPos.X) <= halfSize.X and
						math.abs(localPos.Y) <= halfSize.Y and
						math.abs(localPos.Z) <= halfSize.Z then
						
						-- This handles the chunk creation and indexing automatically
						self:setVoxel(x, y, z, matValue)
					end
				end
			end
		end

		processedCount += 1
		if processedCount >= yieldFrequency then
			processedCount = 0
			task.wait()
		end
	end
end

function VoxelWorld.getChunkKey(self: VoxelWorld, x: number, y: number, z: number): number
	local cx = math.floor(x / CHUNK_SIZE)
	local cy = math.floor(y / CHUNK_SIZE)
	local cz = math.floor(z / CHUNK_SIZE)
	return cx * 1000000 + cy * 1000 + cz
end

function VoxelWorld.getOrCreateChunk(self: VoxelWorld, cx: number, cy: number, cz: number)
	local key = cx * 1000000 + cy * 1000 + cz
	if not self.chunks[key] then
		-- Only allocate 16x16x16 = 4096 bytes per chunk
		self.chunks[key] = {
			data = buffer.create(CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE),
			pos = Vector3.new(cx, cy, cz),
			isEmpty = true -- Track if chunk has any non-air blocks
		}
	end
	return self.chunks[key]
end

function VoxelWorld.setVoxel(self: VoxelWorld, x: number, y: number, z: number, matId: number): ()
	local cx = math.floor(x / CHUNK_SIZE)
	local cy = math.floor(y / CHUNK_SIZE)
	local cz = math.floor(z / CHUNK_SIZE)

	if DEBUG_VOXELS then
		-- Convert grid space to world space
		local worldX = self.min.X + (x * RESOLUTION)
		local worldY = self.min.Y + (y * RESOLUTION)
		local worldZ = self.min.Z + (z * RESOLUTION)
		
		local worldPos = Vector3.new(worldX, worldY, worldZ)

		Draw.box(CFrame.new(worldPos), Vector3.one * RESOLUTION)
	end
	
	local chunk = self:getOrCreateChunk(cx, cy, cz)
	
	-- Local coordinates within chunk
	local lx = x % CHUNK_SIZE
	local ly = y % CHUNK_SIZE
	local lz = z % CHUNK_SIZE
	
	local index = (lx * CHUNK_SIZE * CHUNK_SIZE) + (ly * CHUNK_SIZE) + lz
	buffer.writeu8(chunk.data, index, matId)
	
	if matId ~= 0 then
		chunk.isEmpty = false
	end
end

function VoxelWorld.getVoxel(self: VoxelWorld, x: number, y: number, z: number): number
	local cx = math.floor(x / CHUNK_SIZE)
	local cy = math.floor(y / CHUNK_SIZE)
	local cz = math.floor(z / CHUNK_SIZE)

	local key = cx * 1000000 + cy * 1000 + cz
	local chunk = self.chunks[key]

	if not chunk or chunk.isEmpty then
		return 0 -- Air
	end

	local lx = x % CHUNK_SIZE
	local ly = y % CHUNK_SIZE
	local lz = z % CHUNK_SIZE

	local index = (lx * CHUNK_SIZE * CHUNK_SIZE) + (ly * CHUNK_SIZE) + lz
	return buffer.readu8(chunk.data, index)
end

return VoxelWorld