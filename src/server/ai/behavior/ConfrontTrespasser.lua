--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local ReportType = require(ReplicatedStorage.shared.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local Cell = require(ServerScriptService.server.level.cell.Cell)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

--[=[
	@class ConfrontTrespasser
]=]
local ConfrontTrespasser = {}
ConfrontTrespasser.__index = ConfrontTrespasser
ConfrontTrespasser.ClassName = "ConfrontTrespasser"

export type ConfrontTrespasser = typeof(setmetatable({} :: {
	-- maybe add stuff here
}, ConfrontTrespasser))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & ArmedAgent.ArmedAgent & ReporterAgent.ReporterAgent & DetectionAgent.DetectionAgent

function ConfrontTrespasser.new(): ConfrontTrespasser
	return setmetatable({
		minDuration = math.huge,
		maxDuration = math.huge,
	}, ConfrontTrespasser)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.SPOTTED_TRESPASSER] = MemoryStatus.VALUE_PRESENT
}

function ConfrontTrespasser.getMemoryRequirements(self: ConfrontTrespasser): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ConfrontTrespasser.checkExtraStartConditions(self: ConfrontTrespasser, agent: Agent): boolean
	return true
end

function ConfrontTrespasser.canStillUse(self: ConfrontTrespasser, agent: Agent): boolean
	return agent:getBrain():hasMemoryValue(MemoryModuleTypes.SPOTTED_TRESPASSER)
end

function ConfrontTrespasser.doStart(self: ConfrontTrespasser, agent: Agent): ()
	print("Confronting trespasser - setting angry face")
	
	local brain = agent:getBrain()
	local spottedTrespasser = brain:getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
	local spottedTrespasserPlr = spottedTrespasser:get()
	
	if spottedTrespasser:isPresent() then
		brain:setNullableMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER, spottedTrespasserPlr)
	end

	agent:getFaceControl():setFace("Angry")

	local trespasserAreaName = Cell.getPlayerOccupiedAreaName(spottedTrespasserPlr)
	local reportDialogue: string
	if trespasserAreaName then
		reportDialogue = `Trespasser in the {trespasserAreaName}.`
	else
		reportDialogue = `I've got a trespasser over here.`
	end

	agent:getTalkControl():say(reportDialogue)
end

function ConfrontTrespasser.doStop(self: ConfrontTrespasser, agent: Agent): ()
	agent:getFaceControl():setFace("Neutral")
	agent:getBrain():eraseMemory(MemoryModuleTypes.CONFRONTING_TRESPASSER)
end

function ConfrontTrespasser.doUpdate(self: ConfrontTrespasser, agent: Agent, deltaTime: number): ()
	local brain = agent:getBrain()
	local spottedTrespasser = brain:getMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)
	if spottedTrespasser:isEmpty() then
		return
	end

	local trespasserPlayer = spottedTrespasser:get()
	local statusHolder = PlayerStatusRegistry.getPlayerStatusHolder(trespasserPlayer)
	if not statusHolder then
		error("STATUS_HOLDER_NIL: " .. trespasserPlayer.Name)
	end

	if not statusHolder:hasStatus(PlayerStatusTypes.MINOR_TRESPASSING) then
		print(trespasserPlayer.Name, "No longer trespassing. Erasing memory.")
		brain:eraseMemory(MemoryModuleTypes.SPOTTED_TRESPASSER)

		local detectionManager = agent:getDetectionManager()

		-- TODO: Fucking fix this bullshit thank you.
		-- Find and clear the detection level for this player
		local entity = EntityManager.getEntityByUuid(tostring(trespasserPlayer.UserId))
		if entity then
			local entityUuid = entity.uuid
			-- Clear ALL detection keys for this player
			for key, _ in pairs(detectionManager.detectionLevels) do
				if string.match(key, "^" .. entityUuid .. ":") then
					detectionManager.detectionLevels[key] = nil
				end
			end
		end
	end
end

--

function ConfrontTrespasser.getReactionTIme(self: ConfrontTrespasser, agent: Agent, deltaTime: number): number
	return 0.7
end

return ConfrontTrespasser