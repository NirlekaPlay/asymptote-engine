--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Cell = require(ServerScriptService.server.cell.Cell)
local CellConfig = require(ServerScriptService.server.cell.CellConfig)
local PlayerStatus = require(ServerScriptService.server.player.PlayerStatus)

local UPDATES_PER_SEC = 20
local UPDATE_INTERVAL = 1 / UPDATES_PER_SEC
local timeAccum = 0

local cellConfigs: {
	[string]: CellConfig.Config
} = {
	KillhouseBasicMinorTrespassing = {
		canBeTrespassed = true,
		penalties = {
			disguised = nil,
			undisguised = PlayerStatus.Status.MINOR_TRESPASSING
		}
	},
	JeiasZone = {
		canBeTrespassed = true,
		penalties = {
			disguised = PlayerStatus.Status.MINOR_TRESPASSING,
			undisguised = PlayerStatus.Status.MAJOR_TRESPASSING
		}
	}
}

--[=[
	@class Level
]=]
local Level = {}

function Level.initializeLevel(): ()
	local levelFolder = workspace:FindFirstChild("Level")
	if not levelFolder or not levelFolder:IsA("Folder") then
		warn("Unable to initialize Level: Level not found in Workspace or is not a Folder.")
		return
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
		local cellConfig = cellConfigs[cellName]
		local cframe, size = cellModel:GetBoundingBox()
		local bounds = { CFrame = cframe, Size = size }
		Cell.addCell(cellName, bounds, cellConfig)

		for _, cellChild in ipairs(cellModel:GetChildren()) do
			if not cellChild:IsA("BasePart") then
				continue
			end

			cellChild.Transparency = 1
		end
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