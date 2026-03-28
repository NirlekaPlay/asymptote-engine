--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local MissionSetup = require(ServerScriptService.server.world.level.mission.reading.MissionSetup)
local Scene = require(ServerScriptService.server.world.level.scene.Scene)

--[=[
	@class SceneManager
]=]
local SceneManager = {}
SceneManager.__index = SceneManager

export type SceneManager = typeof(setmetatable({} :: {
	currentScene: Scene?
}, SceneManager))

type Scene = Scene.Scene

function SceneManager.new(): SceneManager
	return setmetatable({
		currentScene = nil :: Scene?
	}, SceneManager)
end

--

--[=[
	This is supposed to start the migration from the old Level class to the new one.
	Do not use this for general purpose scene loading.
]=]
function SceneManager.importFromLoadedScene(
	self: SceneManager,
	missionSetup: MissionSetup.MissionSetup,
	cellsFolder: Folder?
): ()
	local cells = {}
	local parsedConfigs = missionSetup.cells

	if cellsFolder then
		for _, cellModel in cellsFolder:GetChildren() do
			local cell = {}
			cell.name = cellModel.Name
			cell.hasFloor = cellModel:FindFirstChild("Floor") ~= nil
			cell.locationStr = cellModel:GetAttribute("Location") :: string?
			cell.config = parsedConfigs[cellModel.Name] and parsedConfigs[cellModel.Name].config or nil

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

				local bound = {}
				bound.cframe = part.CFrame
				bound.size = part.Size
				bound.type = if type == "Floor" then 0 else 1

				boundsI += 1
				bounds[boundsI] = bound
			end

			cell.bounds = bounds
			table.insert(cells, cell)
		end
	end

	self.currentScene = Scene.new(cells, parsedConfigs)
end

function SceneManager.getActiveScene(self: SceneManager): Scene?
	return self.currentScene
end

return SceneManager