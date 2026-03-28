--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local CellManager = require(ServerScriptService.server.world.level.cell.CellManager)

--[=[
	@class Scene
]=]
local Scene = {}
Scene.__index = Scene

export type Scene = typeof(setmetatable({} :: {
	cellManager: CellManager.CellManager
}, Scene))

function Scene.new(cells, cellConfigs): Scene
	return setmetatable({
		cellManager = CellManager.new(cells, cellConfigs)
	}, Scene)
end

function Scene.getCellManager(self: Scene): CellManager.CellManager
	return self.cellManager
end

return Scene