--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Entity = require(ServerScriptService.server.world.entity.Entity)
local EntitySectionManager = require(ServerScriptService.server.world.level.entity.EntitySectionManager)
local EntityTickList = require(ServerScriptService.server.world.level.entity.EntityTickList)
local LevelCallback = require(ServerScriptService.server.world.level.entity.LevelCallback)

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

	return setmetatable(this, Level) :: Level
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
	debug.profilebegin("level_doUpdate_entities")
	self.entityTickList:forEach(function(entity)
		if entity:isRemoved() then
			return
		end

		entity:update(deltaTime)
	end)
	debug.profileend()
end

return Level