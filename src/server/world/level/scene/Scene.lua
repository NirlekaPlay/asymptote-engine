--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local CellManager = require(ServerScriptService.server.world.level.cell.CellManager)
local MissionSetup = require(ServerScriptService.server.world.level.mission.reading.MissionSetup)
local NavMesh = require(ServerScriptService.server.world.level.navmesh.NavMesh)
local PropManager = require(ServerScriptService.server.world.level.scene.props.PropManager)

--[=[
	@class Scene
]=]
local Scene = {}
Scene.__index = Scene

export type Scene = typeof(setmetatable({} :: {
	cellManager: CellManager.CellManager,
	propManager: PropManager.PropManager,
	sceneConfig: MissionSetup.MissionSetup,
	navMesh: NavMesh.NavMesh,
	_restarting: boolean
}, Scene))

function Scene.new(cells, sceneConfigs): Scene
	return setmetatable({
		cellManager = CellManager.new(cells, sceneConfigs.cells),
		propManager = PropManager.new(),
		sceneConfig = sceneConfigs,
		navMesh = NavMesh.new(),
		_restarting = false
	}, Scene)
end

--

function Scene.update(self: Scene, deltaTime: number): ()
	debug.profilebegin("scene_update_cells")
	self.cellManager:update()
	debug.profileend()
	self.propManager:update(deltaTime)
end

function Scene.restart(self: Scene): ()
	self._restarting = true
	self.propManager:restartProps()
	self._restarting = false
end

function Scene.isRestarting(self: Scene): boolean
	return self._restarting
end

function Scene.getCellManager(self: Scene): CellManager.CellManager
	return self.cellManager
end

function Scene.getSceneConfig(self: Scene): MissionSetup.MissionSetup
	return self.sceneConfig
end

function Scene.getExpressionContext(self: Scene): ExpressionContext.ExpressionContext
	return ExpressionContext.new({})
end

--

function Scene.clear(self: Scene): ()
	self.propManager:destroyAllProps()
end

return Scene