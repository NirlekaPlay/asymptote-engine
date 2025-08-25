--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Cell = require(ServerScriptService.server.cell.Cell)
local CellConfig = require(ServerScriptService.server.cell.CellConfig)

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
			undisguised = "MINOR_TRESPASSING"
		}
	},
	JeiasZone = {
		canBeTrespassed = true,
		penalties = {
			disguised = "MINOR_TRESPASSING",
			undisguised = "MAJOR_TRESPASSING"
		}
	}
}

--[=[
	@class Level
]=]
local Level = {}

for _, inst in ipairs(workspace.Level.Cells:GetChildren()) do
	local cframe, size = inst:GetBoundingBox()
	Cell.addCell(inst.Name, { CFrame = cframe, Size = size }, cellConfigs[inst.Name])
end

function Level.getCellConfig(cellName: string): CellConfig.Config
	return cellConfigs[cellName]
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