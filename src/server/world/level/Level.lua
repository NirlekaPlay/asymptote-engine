--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Cell = require(ServerScriptService.server.world.level.cell.Cell)
local CellConfig = require(ServerScriptService.server.world.level.cell.CellConfig)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)
local Clutter = require(ServerScriptService.server.world.level.clutter.Clutter)

local HIDE_CELLS = true
local DEBUG_MIN_CELLS_TRANSPARENCY = 0.5
local UPDATES_PER_SEC = 20
local UPDATE_INTERVAL = 1 / UPDATES_PER_SEC
local timeAccum = 0

local levelFolder: Folder?
local cellsConfig: { [string]: CellConfig.Config}?
local cellsList: { Model } = {}

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
		cellsConfig = (require :: any)(missionSetupModule).Cells
	end

	local cellsFolder = levelFolder:FindFirstChild("Cells")
	if not cellsFolder or not cellsFolder:IsA("Folder") then
		warn("Unable to initialize Cells: Cells folder not found in Level folder or is not a Folder.")
	else
		Level.initializeCells(cellsFolder)
	end

	local propsFolder = levelFolder:FindFirstChild("Props")
	if propsFolder and (propsFolder:IsA("Model") or propsFolder:IsA("Folder")) then
		Level.initializeClutters(propsFolder, (require :: any)(missionSetupModule).Colors)
	end

	local playerCollidersFolder = levelFolder:FindFirstChild("PlayerColliders")
	if playerCollidersFolder and playerCollidersFolder:IsA("Folder") then
		Level.initializePlayerColliders(playerCollidersFolder)
	end

	local barriersFolder = levelFolder:FindFirstChild("Barrier")
	if barriersFolder and barriersFolder:IsA("Folder") then
		Level.initializePlayerColliders(barriersFolder)
	end
end

function Level.initializePlayerColliders(folder: Folder): ()
	for _, part in ipairs(folder:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.CanTouch = false
		part.AudioCanCollide = false
		part.Anchored = true
		part.CollisionGroup = CollisionGroupTypes.PLAYER_COLLIDER
		part.Transparency = 1
	end
end

function Level.initializeClutters(levelPropsFolder: Model | Folder, colorsMap): ()
	local successfull = Clutter.initialize()
	if successfull then
		Clutter.replacePlaceholdersWithProps(levelPropsFolder, colorsMap)
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

		table.insert(cellsList, cellModel)
	end
end

function Level.getCellConfig(cellName: string): CellConfig.Config?
	return cellsConfig and cellsConfig[cellName] or nil
end

function Level.getCellModels(): {Model}
	return cellsList
end

function Level.hideCell(cellModel: Model): ()
	for _, cellChild in ipairs(cellModel:GetChildren()) do
		if not cellChild:IsA("BasePart") then
			continue
		end

		cellChild.Transparency = 1
		cellChild.CanCollide = false
		cellChild.CanQuery = false
		cellChild.CanTouch = false
		cellChild.AudioCanCollide = false
	end
end

function Level.showCell(cellModel: Model): ()
	for _, cellChild in ipairs(cellModel:GetChildren()) do
		if not cellChild:IsA("BasePart") then
			continue
		end

		cellChild.Transparency = DEBUG_MIN_CELLS_TRANSPARENCY
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