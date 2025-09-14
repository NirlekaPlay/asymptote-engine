--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PanicDialogues = require(ReplicatedStorage.shared.dialogue.PanicDialogues)
local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)

--[=[
	@class GuardPanic
]=]
local GuardPanic = {}
GuardPanic.__index = GuardPanic
GuardPanic.ClassName = "GuardPanic"

export type GuardPanic = typeof(setmetatable({} :: {
}, GuardPanic))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent

function GuardPanic.new(): GuardPanic
	return setmetatable({
		minDuration = math.huge,
		maxDuration = math.huge
	}, GuardPanic)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.REGISTERED,
	[MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID] = MemoryStatus.REGISTERED
}

local ALARMING_STATUSES: { [ PlayerStatus.PlayerStatus ]: true } = {
	[PlayerStatusTypes.ARMED] = true,
	[PlayerStatusTypes.DANGEROUS_ITEM] = true
}

local ALARMING_ENTITY_NAMES: { [string]: true } = {
	["C4"] = true :: true -- my brother in christ
}

function GuardPanic.getMemoryRequirements(self: GuardPanic): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function GuardPanic.checkExtraStartConditions(self: GuardPanic, agent: Agent): boolean
	local susMan = agent:getDetectionManager()

	-- My god.
	for entityKey, detectionValue in pairs(susMan.detectionLevels) do
		local uuid = string.match(entityKey, "^(.-):") :: string
		local keyStatus = string.match(entityKey, "^.-:(.+)") :: string
		local entityObj = EntityManager.getEntityByUuid(uuid)

		-- On a sidenote, this shit should be tirered based on highest priority
		if entityObj and not entityObj.isStatic and entityObj.name == "Player" then
			local statusObj = PlayerStatusTypes.getStatusFromName(keyStatus)
			if statusObj and ALARMING_STATUSES[statusObj] and detectionValue >= 1 then
				local player = entityObj.instance :: Player
				agent:getBrain():setNullableMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID, uuid)
				agent:getBrain():setNullableMemory(MemoryModuleTypes.PANIC_POSITION, player.Character.PrimaryPart.Position)
				return true
			end
		else
			if ALARMING_ENTITY_NAMES[entityObj.name] and detectionValue >= 1 then
				local entityPos: Vector3
				if entityObj.isStatic then
					entityPos = entityObj.position
				else
					local entityInst = entityObj.instance
					if entityInst:IsA("Model") then
						entityPos = entityInst.PrimaryPart.Position
					elseif entityInst:IsA("BasePart") then
						entityPos = entityInst.Position
					end
				end

				if not entityPos then
					warn(uuid, "Does not have a valid way to get position")
					return false
				end

				agent:getBrain():setNullableMemory(MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID, uuid)
				agent:getBrain():setNullableMemory(MemoryModuleTypes.PANIC_POSITION, entityPos)
				return true
			end
		end
	end

	return false
end

function GuardPanic.canStillUse(self: GuardPanic, agent: Agent): boolean
	return true
end

function GuardPanic.doStart(self: GuardPanic, agent: Agent): ()
	agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_PANICKING, true)
	agent:getBrain():eraseMemory(MemoryModuleTypes.FOLLOW_TARGET)
end

function GuardPanic.doStop(self: GuardPanic, agent: Agent): ()
	agent:getBrain():eraseMemory(MemoryModuleTypes.IS_PANICKING)
end

function GuardPanic.doUpdate(self: GuardPanic, agent: Agent, deltaTime: number): ()
	return
end

--

function GuardPanic.getReactionTime(self: GuardPanic, agent: Agent, deltaTime: number): number
	return 0.7
end

return GuardPanic