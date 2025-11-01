--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

--[=[
	@class KillCaughtOrThreateningPlayers
]=]
local KillCaughtOrThreateningPlayers = {}
KillCaughtOrThreateningPlayers.__index = KillCaughtOrThreateningPlayers
KillCaughtOrThreateningPlayers.ClassName = "KillCaughtOrThreateningPlayers"

export type KillCaughtOrThreateningPlayers = typeof(setmetatable({} :: {
}, KillCaughtOrThreateningPlayers))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

function KillCaughtOrThreateningPlayers.new(): KillCaughtOrThreateningPlayers
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, KillCaughtOrThreateningPlayers)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_PRESENT,
	[MemoryModuleTypes.IS_INTIMIDATED] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.TARGETABLE_ENTITIES] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.VISIBLE_ENTITIES] = MemoryStatus.VALUE_PRESENT
}

function KillCaughtOrThreateningPlayers.getMemoryRequirements(self: KillCaughtOrThreateningPlayers): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function KillCaughtOrThreateningPlayers.checkExtraStartConditions(self: KillCaughtOrThreateningPlayers, agent: Agent): boolean
	return true
end

function KillCaughtOrThreateningPlayers.canStillUse(self: KillCaughtOrThreateningPlayers, agent: Agent): boolean
	return true
end

function KillCaughtOrThreateningPlayers.doStart(self: KillCaughtOrThreateningPlayers, agent: Agent): ()
	return
end

function KillCaughtOrThreateningPlayers.doStop(self: KillCaughtOrThreateningPlayers, agent: Agent): ()
	return
end

function KillCaughtOrThreateningPlayers.doUpdate(self: KillCaughtOrThreateningPlayers, agent: Agent, deltaTime: number): ()
	local targetableEntities = agent:getBrain():getMemory(MemoryModuleTypes.TARGETABLE_ENTITIES)
		:orElse({})
	local visibleEntities = agent:getBrain():getMemory(MemoryModuleTypes.VISIBLE_ENTITIES)
		:orElse({})

	for entityUuid in pairs(visibleEntities) do
		local entityObj = EntityManager.getEntityByUuid(entityUuid)
		if not entityObj then
			continue
		end

		if not entityObj.isStatic and entityObj.name == "Player" then
			local player = entityObj.instance :: Player
			if targetableEntities[player] then
				continue
			end

			if not player.Character then
				continue
			end

			local statusHolder = PlayerStatusRegistry.getPlayerStatusHolder(player)
			if not statusHolder then
				continue
			end

			local highestDetectableStatus = statusHolder:getHighestDetectableStatus(true, false)
			if not highestDetectableStatus then
				continue
			end

			if highestDetectableStatus == PlayerStatusTypes.DISGUISED then
				local detMan = agent:getDetectionManager()
				local canDetect = detMan:canAgentDetectThroughDisguise(entityObj, {
					isHeard = false,
					isVisible = true
				})

				if canDetect then
					targetableEntities[player] = true
				end
			else
				targetableEntities[player] = true
			end

			continue
		end
	end

	agent:getBrain():setNullableMemory(MemoryModuleTypes.TARGETABLE_ENTITIES, targetableEntities)
end

return KillCaughtOrThreateningPlayers