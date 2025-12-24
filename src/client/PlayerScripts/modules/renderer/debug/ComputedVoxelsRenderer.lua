--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)

local DEBUG_PATH_NODES_FOLDER_NAME = "DebugComputedNodesClient"
local RESOLUTION = 1

--[=[
	@class ComputedVoxelsRenderer
]=]
local ComputedVoxelsRenderer = {}

local function rpairs(t: {any}): (<a>(tbl: {a}, i: number) -> (number, a), {any}, number)
	return function(tbl, i)
		i -= 1
		if i > 0 then
			return i, tbl[i]
		end
	end, t, #t + 1
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

function ComputedVoxelsRenderer.clear(): ()
	
end

function ComputedVoxelsRenderer.render(): ()
	
end

function ComputedVoxelsRenderer.visualizeComputedNodes(debugNodes: {{pos: Vector3, cost: number}}): ()
	cancelLastDebugThread()

	currentDebugVisualizeComputedNodesThread = task.spawn(function()
		local maxCostFound = 0
		for _, node in debugNodes do
			maxCostFound = math.max(maxCostFound, node.cost)
		end
		
		-- Batch processing
		local BATCH_SIZE = 100
		for i, node in rpairs(debugNodes) do
			local t = maxCostFound > 0 and (node.cost / maxCostFound) or 0
			local color = Color3.new(t, 1 - t, 0)

			Draw.box(
				CFrame.new(node.pos),
				Vector3.one * (RESOLUTION * 0.8),
				color
			).Parent = computedNodesFolder

			-- Yield every X iterations to let the engine breathe
			if i % BATCH_SIZE == 0 then
				task.wait() 
			end
		end
	end)
end

return ComputedVoxelsRenderer