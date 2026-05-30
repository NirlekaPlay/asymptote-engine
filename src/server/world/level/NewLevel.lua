--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Entity = require(ServerScriptService.server.world.entity.Entity)
local Cell = require(ServerScriptService.server.world.level.cell.Cell)
local EntitySectionManager = require(ServerScriptService.server.world.level.entity.EntitySectionManager)
local EntityTickList = require(ServerScriptService.server.world.level.entity.EntityTickList)
local LevelCallback = require(ServerScriptService.server.world.level.entity.LevelCallback)
local MissionSetup = require(ServerScriptService.server.world.level.mission.reading.MissionSetup)
local SceneManager = require(ServerScriptService.server.world.level.scene.SceneManager)

local TICK_RATE = 1 / 20
local MAX_TICKS_PER_FRAME = 5

--[=[
	@class Level
]=]
local Level = {}
Level.__index = Level

export type Level = typeof(setmetatable({} :: {
	entityManager: EntitySectionManager.EntitySectionManager,
	entityTickList: EntityTickList.EntityTickList,
	sceneManager: SceneManager.SceneManager,
	callback: LevelCallback,
	isHandlingTick: boolean,
	--
	_accumulator: number
}, Level))

type Entity = Entity.Entity
type LevelCallback = LevelCallback.LevelCallback<Entity>

function Level.new(): Level
	local this = {
		entityTickList = EntityTickList.new(),
		isHandlingTick = false,
		_accumulator = 0
	}

	--

	local Callback = {}
	Callback.__index = Callback

	function Callback.new(): LevelCallback
		return setmetatable({}, Callback) :: LevelCallback
	end

	function Callback.onTickingStart(self: LevelCallback, entity: Entity): ()
		this.entityTickList:add(entity)
	end

	function Callback.onTickingStop(self: LevelCallback, entity: Entity): ()
		this.entityTickList:remove(entity)
	end

	this.entityManager = EntitySectionManager.new(Callback)

	--

	local self = setmetatable(this, Level) :: Level

	self.sceneManager = SceneManager.new(self :: any)

	return self
end

--

function Level.getEntitiesInRadius(self: Level, origin: Vector3, radius: number): {Entity}
	return self.entityManager:getEntitiesInRange(origin, 0, radius)
end

function Level.removeAllEntities(self: Level): ()
	for entity in self.entityManager:getAllEntities() do
		entity:remove(Entity.RemovalReason.DISCARDED)
	end
end

function Level.getPlayerCell(self: Level, player: Player): Cell.Cell?
	local activeScene = self.sceneManager:getActiveScene()
	if not activeScene then
		return nil
	end

	return activeScene:getCellManager():getPlayerCell(player)
end

--

function Level.addFreshEntity(self: Level, entity: Entity): ()
	if entity:isRemoved() then
		warn(`Attempt to add entity '{tostring(entity)}' that is already flagged for removal`)
		return
	else
		self.entityManager:addEntity(entity)
	end
end

--

function Level.getActiveSceneConfig(self: Level): MissionSetup.MissionSetup?
	local scene =  self.sceneManager:getActiveScene()
	if not scene then
		return nil
	end

	return scene:getSceneConfig()
end

function Level.restartScene(self: Level): ()
	self.sceneManager:restartScene()
end

function Level.clearScene(self: Level): ()
	self.sceneManager:clear()
end

function Level.loadScene(self: Level, sceneName: string): ()
	return self.sceneManager:loadScene(sceneName)
end

function Level.getMapList(self: Level): {string}
	return self.sceneManager:getMapList()
end

function Level.isSceneRestarting(self: Level): boolean
	return self.sceneManager:isSceneRestarting()
end

--

function Level.update(self: Level, deltaTime: number): ()
	if self.isHandlingTick then
		return
	end

	self.isHandlingTick = true
	self._accumulator += deltaTime

	local ticks = 0

	while self._accumulator >= TICK_RATE and ticks < MAX_TICKS_PER_FRAME do
		self:doUpdate(TICK_RATE)
		self._accumulator -= TICK_RATE
		ticks += 1
	end

	if self._accumulator > TICK_RATE * MAX_TICKS_PER_FRAME then
		self._accumulator = 0
	end

	self.isHandlingTick = false
end

function Level.doUpdate(self: Level, deltaTime: number): ()
	debug.profilebegin("level_doUpdate")
	debug.profilebegin("entities")
	self.entityTickList:forEach(function(entity)
		if entity:isRemoved() then
			return
		end

		entity:update(deltaTime)
	end)
	debug.profileend()
	debug.profilebegin("sceneManager")
	self.sceneManager:update(deltaTime)
	debug.profileend()
	debug.profileend()
end

return Level