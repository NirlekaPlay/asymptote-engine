--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Heap = require(ServerScriptService.server.world.level.voxel.Heap)

local DEBUG_PATH_NODES = true

--[=[
	TODOs:
	This is fast, sure, but any resolution below 4 will crash the buffer.
	I propose using a chunk-based system and only allocate chunks where
	stuff actually exists there. If not, just don't allocate at all.
]=]

--[=[
	@class VoxelWorld

	Implementation of a voxel-based world for calculating
	sound propagation.
]=]
local VoxelWorld = {}
VoxelWorld.__index = VoxelWorld

local RESOLUTION = 4
local MATERIALS = {
	[Enum.Material.Air] = 0,
	[Enum.Material.Wood] = 1,
	[Enum.Material.Concrete] = 2,
	[Enum.Material.Metal] = 3,
}
local WEIGHTS = { [0] = 1, [1] = 15, [2] = 50, [3] = 150 }

local NEIGHBOR_OFFSETS = {
	Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
	Vector3.new(0, 1, 0), Vector3.new(0, -1, 0),
	Vector3.new(0, 0, 1), Vector3.new(0, 0, -1)
}

local function snapToGrid(vector: Vector3)
	return Vector3.new(
		math.floor(vector.X / RESOLUTION) * RESOLUTION,
		math.floor(vector.Y / RESOLUTION) * RESOLUTION,
		math.floor(vector.Z / RESOLUTION) * RESOLUTION
	)
end

function VoxelWorld.new(min: Vector3, max: Vector3)
	local self = setmetatable({}, VoxelWorld)
	self.Size = (max - min) / RESOLUTION
	self.Min = min
	self.SizeX = math.ceil(self.Size.X)
	self.SizeY = math.ceil(self.Size.Y)
	self.SizeZ = math.ceil(self.Size.Z)
	-- Allocate 1 byte per voxel
	self.Data = buffer.create(self.SizeX * self.SizeY * self.SizeZ)
	
	-- Cache for faster index calculation
	self.YZMultiplier = self.SizeY * self.SizeZ
	self.ZMultiplier = self.SizeZ
	
	return self
end

function VoxelWorld:GetIndex(x, y, z)
	return (x * self.YZMultiplier) + (y * self.ZMultiplier) + z
end

-- Fast hash function for 3D coordinates - avoid string allocation
local function hashPos(x, y, z, sizeY, sizeZ)
	return x * 1000000 + y * 1000 + z
end

function VoxelWorld:IsInBounds(x, y, z)
	return x >= 0 and x < self.SizeX 
	   and y >= 0 and y < self.SizeY 
	   and z >= 0 and z < self.SizeZ
end

function VoxelWorld:Visualize()
	-- Clean up previous visualization
	local folder = workspace:FindFirstChild("VoxelDebug") or Instance.new("Folder", workspace)
	folder.Name = "VoxelDebug"
	folder:ClearAllChildren()

	for x = 0, self.SizeX - 1 do
		for y = 0, self.SizeY - 1 do
			for z = 0, self.SizeZ - 1 do
				local matId = buffer.readu8(self.Data, self:GetIndex(x, y, z))
				
				-- Only visualize if not Air (0)
				if matId > 0 and matId == 2 then
					print("yay?")
					local pos = self.Min + Vector3.new(x, y, z) * RESOLUTION
					
					local adorn = Instance.new("BoxHandleAdornment")
					adorn.Size = Vector3.one * RESOLUTION
					adorn.CFrame = CFrame.new(pos)
					adorn.Color3 = (matId == 2) and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)
					adorn.Transparency = 0.5
					adorn.AlwaysOnTop = false
					adorn.Adornee = workspace.Terrain
					adorn.Parent = folder
				end
			end
		end
	end
end

function VoxelWorld:Voxelize(parent: Instance)
	local bufferData = self.Data
	local minBounds = self.Min
	
	-- Clear existing buffer
	buffer.fill(bufferData, 0, 0, buffer.len(bufferData))

	-- Filter parts first to avoid checking non-baseparts
	local parts = {}
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("BasePart") then
			Draw.part(descendant)
			table.insert(parts, descendant)
		end
	end

	local processedCount = 0
	local yieldFrequency = 500

	for _, part in ipairs(parts) do
		local cf = part.CFrame
		local size = part.Size
		local halfSize = size / 2
		
		-- Get AABB for rotated parts
		local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector
		local absSize = Vector3.new(
			math.abs(right.X * size.X) + math.abs(up.X * size.Y) + math.abs(look.X * size.Z),
			math.abs(right.Y * size.X) + math.abs(up.Y * size.Y) + math.abs(look.Y * size.Z),
			math.abs(right.Z * size.X) + math.abs(up.Z * size.Y) + math.abs(look.Z * size.Z)
		)

		local minV = (cf.Position - (absSize / 2) - minBounds) / RESOLUTION
		local maxV = (cf.Position + (absSize / 2) - minBounds) / RESOLUTION

		local matValue = MATERIALS[part.Material.Name] or 1

		-- Loop through potential voxel grid area WITH BOUNDS CHECKS INSIDE
		for x = math.floor(minV.X), math.ceil(maxV.X) do
			-- Bounds check for X
			if x < 0 or x >= self.SizeX then continue end
			
			for y = math.floor(minV.Y), math.ceil(maxV.Y) do
				if y < 0 or y >= self.SizeY then continue end
				
				for z = math.floor(minV.Z), math.ceil(maxV.Z) do
					if z < 0 or z >= self.SizeZ then continue end
					
					-- Precision check (OBB Logic)
					local worldPos = minBounds + Vector3.new(x, y, z) * RESOLUTION
					local localPos = cf:PointToObjectSpace(worldPos)
					
					-- If point is inside the part's actual volume
					if math.abs(localPos.X) <= halfSize.X and
					   math.abs(localPos.Y) <= halfSize.Y and
					   math.abs(localPos.Z) <= halfSize.Z then
						
						local index = self:GetIndex(x, y, z)
						buffer.writeu8(bufferData, index, matValue)
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
	print("Voxelization Complete!")
end

local currentDebugThread: thread? = nil
local debugFolder = workspace:FindFirstChild("DebugNodes") or Instance.new("Folder", workspace)
debugFolder.Name = "DebugNodes"

local function showDebugParts(debugNodes): ()
	-- Debug: Visualize all explored nodes
	if DEBUG_PATH_NODES then
		if currentDebugThread then
			task.cancel(currentDebugThread)
			debugFolder:ClearAllChildren()
		end
		currentDebugThread = task.spawn(function()
			local maxCostFound = 0
			for _, node in ipairs(debugNodes) do
				if node.cost > maxCostFound then maxCostFound = node.cost end
			end
			
			for _, node in ipairs(debugNodes) do
				-- Color gradient: green (low cost) -> red (high cost)
				local t = maxCostFound > 0 and (node.cost / maxCostFound) or 0
				local color = Color3.new(t, 1 - t, 0)
				
				local debugPart = Draw.box(
					CFrame.new(node.pos),
					Vector3.one * (RESOLUTION * 0.8), -- Slightly smaller than voxel
					color
				)
				debugPart.Parent = debugFolder
				--task.wait() -- Yield each frame to avoid lag spike
			end
		end)
	end
end

function VoxelWorld:GetSoundPath(startPos: Vector3, endPos: Vector3, maxCost: number)
	local startV = (snapToGrid(startPos) - self.Min) / RESOLUTION
	local endV = (snapToGrid(endPos) - self.Min) / RESOLUTION
	
	-- Round to integers
	local startX, startY, startZ = math.floor(startV.X), math.floor(startV.Y), math.floor(startV.Z)
	local endX, endY, endZ = math.floor(endV.X), math.floor(endV.Y), math.floor(endV.Z)
	
	-- Bounds check
	if not self:IsInBounds(startX, startY, startZ) or not self:IsInBounds(endX, endY, endZ) then
		return math.huge
	end
	
	local openList = Heap.new()
	local closedList = {} -- Use hash table instead of string keys
	
	-- Calculate initial heuristic
	local dx = math.abs(endX - startX)
	local dy = math.abs(endY - startY)
	local dz = math.abs(endZ - startZ)
	local initialH = math.sqrt(dx*dx + dy*dy + dz*dz)
	
	openList:push({x = startX, y = startY, z = startZ, g = 0, f = initialH})
	
	local iterations = 0
	local maxIterations = 10000 -- Prevent infinite loops
	
	-- Debug visualization setup
	local debugNodes = {}
	
	while not openList:isEmpty() and iterations < maxIterations do
		iterations += 1
		local current = openList:pop() :: Heap.Node -- Unlikely to return nil
		local cx, cy, cz = current.x, current.y, current.z
		
		-- Debug: Store visited node
		if DEBUG_PATH_NODES then
			local worldPos = self.Min + Vector3.new(cx, cy, cz) * RESOLUTION
			table.insert(debugNodes, {pos = worldPos, cost = current.g})
		end
		
		-- Check if reached goal (within 1 voxel)
		dx = cx - endX
		dy = cy - endY
		dz = cz - endZ
		if dx*dx + dy*dy + dz*dz < 2 then
			showDebugParts(debugNodes)
			return current.g 
		end
		
		-- Use integer hash instead of string
		local key = hashPos(cx, cy, cz, self.SizeY, self.SizeZ)
		
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
			
			-- Bounds checking
			if not self:IsInBounds(nx, ny, nz) then continue end
			
			-- Check if already visited
			local nkey = hashPos(nx, ny, nz, self.SizeY, self.SizeZ)
			if closedList[nkey] then continue end
			
			-- Get material and calculate cost
			local matId = buffer.readu8(self.Data, self:GetIndex(nx, ny, nz))
			local stepCost = WEIGHTS[matId] or 1
			local g = current.g + stepCost
			
			-- Early termination if over budget
			if g > maxCost then continue end
			
			-- Calculate heuristic (Manhattan distance is faster than Euclidean)
			dx = math.abs(endX - nx)
			dy = math.abs(endY - ny)
			dz = math.abs(endZ - nz)
			local h = dx + dy + dz -- Manhattan distance
			
			openList:push({x = nx, y = ny, z = nz, g = g, f = g + h})
		end
	end
	
	if iterations >= maxIterations then
		warn("VoxelWorld :: Pathfinding hit iteration limit")
	end

	showDebugParts(debugNodes)
	
	return math.huge
end

return VoxelWorld