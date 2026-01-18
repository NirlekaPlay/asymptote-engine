--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)

--[=[
	@class DummyBehavior
]=]
local DummyBehavior = {}
DummyBehavior.__index = DummyBehavior
DummyBehavior.ClassName = "DummyBehavior"

export type DummyBehavior = typeof(setmetatable({} :: {
}, DummyBehavior))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

function DummyBehavior.new(): DummyBehavior
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, DummyBehavior)
end

local MEMORY_REQUIREMENTS = {}

function DummyBehavior.getMemoryRequirements(self: DummyBehavior): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function DummyBehavior.checkExtraStartConditions(self: DummyBehavior, agent: Agent): boolean
	return true
end

function DummyBehavior.canStillUse(self: DummyBehavior, agent: Agent): boolean
	return false
end

function DummyBehavior.doStart(self: DummyBehavior, agent: Agent): ()
	print("DummyBehavior::doStart() called")
end

function DummyBehavior.doStop(self: DummyBehavior, agent: Agent): ()
	print("DummyBehavior::doStop() called")
end

function DummyBehavior.doUpdate(self: DummyBehavior, agent: Agent, deltaTime: number): ()
	print("DummyBehavior::doUpdate() called")

	-- Most logic runs here, probably. This is your workspace. The only thing you're gonna really touch
	-- is probably doStart and doStop, but other methods are crucial.

	-- Here are the main APIs:

	-- Detections and shit.
	local detectionManager = agent:getDetectionManager()
	local focusingTarget = detectionManager:getFocusingTarget() -- returns an EntityPriority data.

	-- Entities. (probably the shittest part)
	local entity = EntityManager.getEntityByUuid(focusingTarget.entityUuid)
	-- the new entity architecture is still experimental, so here we go...
	-- check if the entity is a player:
	local isPlayer = entity and not entity.isStatic and entity.name == "Player"
	local playerInst = entity.instance -- the Player instance itself

	-- Managing memories:
	local brain = agent:getBrain() -- get the brain first
	-- theres a shitton of memory modules there, these are just acting like "enums"
	-- the modules themselves dont actually store shit. theyre just identifiers.

	-- sets the memory. if its nil, it just simply erases the memory.
	brain:setNullableMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER, playerInst)

	-- basically the same as the last one but it will be erased after `ttl` seconds.
	brain:setMemoryWithExpiry(MemoryModuleTypes.CONFRONTING_TRESPASSER, playerInst, 5)

	brain:eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER) -- duh.

	-- this returns an Optional<T> exactly like Java, where `T` is the data that the memory module holds.
	-- for example, this memory holds a value of type Player.
	local confrontingTrespasser = brain:getMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
	confrontingTrespasser:isEmpty()
	confrontingTrespasser:isPresent()
	confrontingTrespasser:get() -- will throw an error if its empty, be sure of that
	-- among other stuff, you should probably learn Java optionals.

	-- though we do have what is known as Controls on the Agent:
	local optionalSpeedModifier = 1.2
	agent:getNavigation():moveToPos(Vector3.zero, optionalSpeedModifier) -- and stuff
	-- it is often recommended to set memories so that other behaviors, known as "sinks" for their
	-- roles, actually do the stuff. for example:

	-- Expressions, so your Agent wont be so soulless.

	agent:getFaceControl():setFace("Angry") -- Neutral | Unconscious | Shocked | Neutral

	agent:getTalkControl():say("Watashi wa jagaimo desu.")
	-- automatically calculates the sentence duration, so it moves on to the next one
	agent:getTalkControl():saySequences({"Hello there lad", "You seem to be in the wrong place innit?"})
	-- picks between random dialogues
	agent:getTalkControl():sayRandomSequences({{"Woah!", "Easy there!"}, {"Oi!", "Get back here!"}})
	-- says a dialogue segment data
	agent:getTalkControl():saySegment({
		text = "da text",
		customSpeechDur = 2.5 -- optional to override the automatic sentence duration calculation
	})
end

return DummyBehavior