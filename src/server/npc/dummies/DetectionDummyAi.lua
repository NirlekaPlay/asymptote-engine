--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Agent = require(ServerScriptService.server.Agent)
local Brain = require(ServerScriptService.server.ai.Brain)
local Activity = require(ServerScriptService.server.ai.behavior.Activity)
local BehaviorWrapper = require(ServerScriptService.server.ai.behavior.BehaviorWrapper)
local ConfrontTrespasser = require(ServerScriptService.server.ai.behavior.ConfrontTrespasser)
local EnterCombatActivity = require(ServerScriptService.server.ai.behavior.EnterCombatActivity)
local FleeToEscapePoints = require(ServerScriptService.server.ai.behavior.FleeToEscapePoints)
local FollowPlayerSink = require(ServerScriptService.server.ai.behavior.FollowPlayerSink)
local GuardPanic = require(ServerScriptService.server.ai.behavior.GuardPanic)
local KillCaughtOrThreateningPlayers = require(ServerScriptService.server.ai.behavior.KillCaughtOrThreateningPlayers)
local KillTarget = require(ServerScriptService.server.ai.behavior.KillTarget)
local KillTargetableEntities = require(ServerScriptService.server.ai.behavior.KillTargetableEntities)
local LookAndFaceAtTargetSink = require(ServerScriptService.server.ai.behavior.LookAndFaceAtTargetSink)
local LookAtSuspiciousEntities = require(ServerScriptService.server.ai.behavior.LookAtSuspiciousEntities)
local PleaForMercy = require(ServerScriptService.server.ai.behavior.PleaForMercy)
local ReactToDisguisedPlayers = require(ServerScriptService.server.ai.behavior.ReactToDisguisedPlayers)
local ReportMajorTrespasser = require(ServerScriptService.server.ai.behavior.ReportMajorTrespasser)
local ReportSuspiciousCriminal = require(ServerScriptService.server.ai.behavior.ReportSuspiciousCriminal)
local ReportSuspiciousPlayer = require(ServerScriptService.server.ai.behavior.ReportSuspiciousPlayer)
local RetreatToCombatNodes = require(ServerScriptService.server.ai.behavior.RetreatToCombatNodes)
local SetIsCuriousMemory = require(ServerScriptService.server.ai.behavior.SetIsCuriousMemory)
local SetPanicFace = require(ServerScriptService.server.ai.behavior.SetPanicFace)
local ValidatePrioritizedEntity = require(ServerScriptService.server.ai.behavior.ValidatePrioritizedEntity)
local WalkToRandomPost = require(ServerScriptService.server.ai.behavior.WalkToRandomPost)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local SensorFactories = require(ServerScriptService.server.ai.sensing.SensorFactories)

local GuardAi = {}

type Agent = Agent.Agent
type Brain<T> = Brain.Brain<T>

local MEMORY_TYPES = {
	MemoryModuleTypes.TARGETABLE_ENTITIES,
	MemoryModuleTypes.LOOK_TARGET,
	MemoryModuleTypes.KILL_TARGET,
	MemoryModuleTypes.FOLLOW_TARGET,
	MemoryModuleTypes.PANIC_SOURCE_ENTITY_UUID,
	MemoryModuleTypes.PRIORITIZED_ENTITY,
	MemoryModuleTypes.IS_INVESTIGATING,
	MemoryModuleTypes.FLEE_TO_POSITION,
	MemoryModuleTypes.IS_COMBAT_MODE,
	MemoryModuleTypes.IS_CURIOUS,
	MemoryModuleTypes.IS_PANICKING,
	MemoryModuleTypes.IS_FLEEING,
	MemoryModuleTypes.IS_INTIMIDATED,
	MemoryModuleTypes.DESIGNATED_POSTS,
	MemoryModuleTypes.PATROL_STATE,
	MemoryModuleTypes.CURRENT_POST,
	MemoryModuleTypes.TARGET_POST,
	MemoryModuleTypes.POST_VACATE_COOLDOWN,
	MemoryModuleTypes.CONFRONTING_TRESPASSER,
	MemoryModuleTypes.TRESPASSERS_WARNS,
	MemoryModuleTypes.TRESPASSERS_ENCOUNTERS,
	MemoryModuleTypes.SPOTTED_TRESPASSER,
	MemoryModuleTypes.SPOTTED_DISGUISED_PLAYER,
	MemoryModuleTypes.SPOTTED_CRIMINAL,
	MemoryModuleTypes.REPORTING_ON,
	MemoryModuleTypes.PANIC_POSITION,
	MemoryModuleTypes.HAS_FLED,
	MemoryModuleTypes.HAS_RETREATED
}
 
local SENSOR_FACTORIES = {
	SensorFactories.VISIBLE_ENTITIES_SENSOR,
	SensorFactories.HEARING_PLAYERS_SENSOR
}

function GuardAi.makeBrain(agent: Agent)
	local brain = Brain.new(agent, MEMORY_TYPES, SENSOR_FACTORIES)
	GuardAi.initCoreActivity(brain)
	GuardAi.initWorkActivity(brain)
	GuardAi.initPanicActivity(brain)
	GuardAi.initConfrontActivity(brain)
	GuardAi.initFightActivity(brain)
	brain:setNullableMemory(MemoryModuleTypes.DESIGNATED_POSTS, agent.designatedPosts)
	brain:setCoreActivities({Activity.CORE})
	brain:setDefaultActivity(Activity.IDLE)
	brain:useDefaultActivity()
	return brain
end

function GuardAi.initCoreActivity(brain: Brain<Agent>): ()
	brain:addActivity(Activity.CORE, 2, {
		BehaviorWrapper.new(EnterCombatActivity.new()),
		BehaviorWrapper.new(ValidatePrioritizedEntity.new()),
		BehaviorWrapper.new(SetIsCuriousMemory.new()),
		BehaviorWrapper.new(LookAtSuspiciousEntities.new()),
		BehaviorWrapper.new(LookAndFaceAtTargetSink.new()),
		BehaviorWrapper.new(GuardPanic.new()),
		BehaviorWrapper.new(ReportSuspiciousCriminal.new()),
		BehaviorWrapper.new(ReportMajorTrespasser.new()),
		BehaviorWrapper.new(ConfrontTrespasser.new()),
		BehaviorWrapper.new(ReactToDisguisedPlayers.new()),
		BehaviorWrapper.new(ReportSuspiciousPlayer.new()),
		BehaviorWrapper.new(FollowPlayerSink.new())
	})
end

function GuardAi.initWorkActivity(brain: Brain<Agent>): ()
	brain:addActivityWithConditions(Activity.WORK, 4, {
		BehaviorWrapper.new(WalkToRandomPost.new()),
	}, {
		[MemoryModuleTypes.CONFRONTING_TRESPASSER] = MemoryStatus.VALUE_ABSENT,
		[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
		[MemoryModuleTypes.KILL_TARGET] = MemoryStatus.VALUE_ABSENT
	})
end

function GuardAi.initPanicActivity(brain: Brain<Agent>): ()
	brain:addActivityWithConditions(Activity.PANIC, 1, {
		BehaviorWrapper.new(SetPanicFace.new()),
		BehaviorWrapper.new(FleeToEscapePoints.new()),
		BehaviorWrapper.new(KillTarget.new()),
		BehaviorWrapper.new(PleaForMercy.new())
	}, {
		[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_PRESENT
	})
end

function GuardAi.initConfrontActivity(brain: Brain<Agent>): ()
	brain:addActivityWithConditions(Activity.CONFRONT, 3, {
		BehaviorWrapper.new(ConfrontTrespasser.new()),
		BehaviorWrapper.new(ReportMajorTrespasser.new())
	}, {
		[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
		[MemoryModuleTypes.CONFRONTING_TRESPASSER] = MemoryStatus.VALUE_PRESENT
	})
end

function GuardAi.initFightActivity(brain: Brain<Agent>): ()
	brain:addActivityWithConditions(Activity.FIGHT, 1, {
		BehaviorWrapper.new(KillCaughtOrThreateningPlayers.new()),
		BehaviorWrapper.new(KillTargetableEntities.new()),
		BehaviorWrapper.new(KillTarget.new()),
		BehaviorWrapper.new(RetreatToCombatNodes.new())
	}, {
		[MemoryModuleTypes.IS_COMBAT_MODE] = MemoryStatus.VALUE_PRESENT,
	})
end

function GuardAi.updateActivity(guard: Agent): ()
	guard:getBrain():setActiveActivityToFirstValid({
		Activity.FIGHT, Activity.PANIC, Activity.CONFRONT, Activity.WORK
	})
end

return GuardAi