--!strict

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local CellManager = require(ServerScriptService.server.world.level.cell.CellManager)
local MissionSetupReaderV1 = require(ServerScriptService.server.world.level.mission.reading.readers.MissionSetupReaderV1)

local cellsFolder = ((workspace :: any).DebugMission.Cells :: Folder)
local cells: { CellManager.Cell } = {}

for _, cellModel in cellsFolder:GetChildren() do
	local cell = {} :: CellManager.Cell
	cell.name = cellModel.Name
	cell.hasFloor = cellModel:FindFirstChild("Floor") ~= nil
	cell.locationStr = cellModel:GetAttribute("Location") :: string?

	local bounds = {}
	local boundsI = 0
	for _, part in cellModel:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end

		local type = part.Name
		if type ~= "Floor" and type ~= "Roof" then
			continue
		end

		local bound = {} :: CellManager.Bounds
		bound.cframe = part.CFrame
		bound.size = part.Size
		bound.type = if type == "Floor" then 0 else 1

		boundsI += 1
		bounds[boundsI] = bound
	end

	cell.bounds = bounds
	table.insert(cells, cell)
end

local parsedConfigs = MissionSetupReaderV1.parse(workspace.DebugMission.MissionSetup).cells

print(cells, parsedConfigs)
local cellManager = CellManager.new(cells, parsedConfigs)

local TARGET_TPS = 20
local TIME_STEP = 1 / TARGET_TPS
local accumulatedTime = 0

RunService.PreSimulation:Connect(function(deltaTime)
	accumulatedTime += deltaTime

	while accumulatedTime >= TIME_STEP do
		cellManager:update()
		accumulatedTime -= TIME_STEP
	end
end)
