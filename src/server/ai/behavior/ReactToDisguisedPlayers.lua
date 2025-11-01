--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GuardGenericDialogues = require(ReplicatedStorage.shared.dialogue.GuardGenericDialogues)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local ReportType = require(ReplicatedStorage.shared.report.ReportType)
local Agent = require(ServerScriptService.server.Agent)
local DetectionAgent = require(ServerScriptService.server.DetectionAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

--[=[
	@class ReactToDisguisedPlayers
]=]
local ReactToDisguisedPlayers = {}
ReactToDisguisedPlayers.__index = ReactToDisguisedPlayers
ReactToDisguisedPlayers.ClassName = "ReactToDisguisedPlayers"

export type ReactToDisguisedPlayers = typeof(setmetatable({} :: {
}, ReactToDisguisedPlayers))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & DetectionAgent.DetectionAgent & ReporterAgent.ReporterAgent

function ReactToDisguisedPlayers.new(): ReactToDisguisedPlayers
	return setmetatable({
		minDuration = nil :: number?,
		maxDuration = nil :: number?
	}, ReactToDisguisedPlayers)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.IS_INTIMIDATED] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
	[MemoryModuleTypes.VISIBLE_ENTITIES] = MemoryStatus.VALUE_PRESENT
}

function ReactToDisguisedPlayers.getMemoryRequirements(self: ReactToDisguisedPlayers): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function ReactToDisguisedPlayers.checkExtraStartConditions(self: ReactToDisguisedPlayers, agent: Agent): boolean
	local detetectionManager = agent:getDetectionManager()
	local focusingTarget = detetectionManager:getFocusingTarget()
	if focusingTarget then
		local detLevel = detetectionManager:getDetectionLevel(focusingTarget.entityUuid)
		if not detLevel or detLevel < 1 or focusingTarget.status ~= PlayerStatusTypes.DISGUISED.name then
			return false
		end
		return true
	end

	return false
end

function ReactToDisguisedPlayers.canStillUse(self: ReactToDisguisedPlayers, agent: Agent): boolean
	return true
end

function ReactToDisguisedPlayers.doStart(self: ReactToDisguisedPlayers, agent: Agent): ()
	local disguisedPlayer = self:getDetectedDisguisedPlayer(agent)
	local playerStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(disguisedPlayer)
	if not playerStatusHolder then
		warn("UNDEFINED BEHAVIOR: PLAYER STATUS HOLDER OF", disguisedPlayer, "IS NIL.")
		return
	end

	local talkCtrl = agent:getTalkControl()
	local reportCtrl = agent:getReportControl()
	local faceCtrl = agent:getFaceControl()

	--local disguise = playerStatusHolder:getDisguise()
	local reportDialogue = talkCtrl.randomlyChosoeDialogueSequences(GuardGenericDialogues["status.disguised"])
	local reportDialogueTotalDur = talkCtrl.getDialoguesTotalSpeechDuration(reportDialogue)

	faceCtrl:setFace("Angry")
	talkCtrl:saySequences(reportDialogue)
	reportCtrl:reportWithCustomDur(ReportType.INTRUDER_SPOTTED, 2, reportDialogueTotalDur)
end

function ReactToDisguisedPlayers.doStop(self: ReactToDisguisedPlayers, agent: Agent): ()
	return
end

function ReactToDisguisedPlayers.doUpdate(self: ReactToDisguisedPlayers, agent: Agent, deltaTime: number): ()
	return
end

--

function ReactToDisguisedPlayers.getDetectedDisguisedPlayer(self: ReactToDisguisedPlayers, agent: Agent): Player
	local detetectionManager = agent:getDetectionManager()
	local focusingTarget = detetectionManager:getFocusingTarget()
	
	if focusingTarget then
		local status = focusingTarget.status
		-- TODO: Fix inconsistent status getting and setting
		if status == PlayerStatusTypes.DISGUISED.name then
			local entity = EntityManager.getEntityByUuid(focusingTarget.entityUuid)
			if not entity or entity.name ~= "Player" or entity.isStatic == true then
				error("The fucking entity is not a valid Player or is nil. Non-players shouldnt even have disguised statuses!!")
			end
			return entity.instance :: Player
		end
	else
		error("Strange, ReactToDisguisedPlayers:doStart() is called but focusing target is nil.")
	end

	error("Invalid condition.") -- will this ever get executed anyway?
end

function ReactToDisguisedPlayers.getReactionTime(self: ReactToDisguisedPlayers, agent: Agent, deltaTime: number): number
	return agent:getRandom():NextNumber(0.5, 0.7)
end

return ReactToDisguisedPlayers