--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Cell = require(ServerScriptService.server.cell.Cell)
local CellConfig = require(ServerScriptService.server.cell.CellConfig)

local HIDE_CELLS = false
local UPDATES_PER_SEC = 20
local UPDATE_INTERVAL = 1 / UPDATES_PER_SEC
local timeAccum = 0

local levelFolder: Folder?
local cellsConfig: { [string]: CellConfig.Config}?

--[=[
	@class Level
]=]
local Level = {}

function Level.initializeLevel(): ()
	levelFolder = workspace:FindFirstChild("Level") :: Folder?
	if not levelFolder or not levelFolder:IsA("Folder") then
		warn("Unable to initialize Level: Level not found in Workspace or is not a Folder.")
		return
	end

	local missionSetupModule = levelFolder:FindFirstChild("MissionSetup") :: ModuleScript?
	if not missionSetupModule or not missionSetupModule:IsA("ModuleScript") then
		warn("Unable to initialize Mission: MissionSetup module not found in Level folder or is not a ModuleScript.")
	else
		cellsConfig = require(missionSetupModule).Cells
	end

	local cellsFolder = levelFolder:FindFirstChild("Cells")
	if not cellsFolder or not cellsFolder:IsA("Folder") then
		warn("Unable to initialize Cells: Cells folder not found in Level folder or is not a Folder.")
	else
		Level.initializeCells(cellsFolder)
	end
end

function Level.initializeCells(cellsFolder: Folder): ()
	for _, cellModel in ipairs(cellsFolder:GetChildren()) do
		if not cellModel:IsA("Model") then
			continue
		end

		local cellName = cellModel.Name
		local cellConfig = Level.getCellConfig(cellName)
		local cframe, size = cellModel:GetBoundingBox()
		local areaName = cellModel:GetAttribute("AreaName") :: string?
		local bounds = { CFrame = cframe, Size = size, AreaName = areaName }
		Cell.addCell(cellName, bounds, cellConfig)

		if HIDE_CELLS then
			Level.hideCell(cellModel)
		end
	end
end

function Level.getCellConfig(cellName: string): CellConfig.Config?
	return cellsConfig and cellsConfig[cellName] or nil
end

function Level.hideCell(cellModel: Model): ()
	for _, cellChild in ipairs(cellModel:GetChildren()) do
		if not cellChild:IsA("BasePart") then
			continue
		end

		cellChild.Transparency = 1
	end
end

function Level.update(deltaTime: number): ()
	timeAccum += deltaTime
	if timeAccum >= UPDATE_INTERVAL then
		timeAccum = 0
		Level.doUpdate(deltaTime)
	end
end

function Level.doUpdate(deltaTime: number): ()
	Level.updateCells()
end

function Level.updateCells(): ()
	Cell.update()
end

return Level