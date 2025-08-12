--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")
local Agent = require(ServerScriptService.server.Agent)
local Brain = require(ServerScriptService.server.ai.Brain)
local Activity = require(ServerScriptService.server.ai.behavior.Activity)
local BehaviorWrapper = require(ServerScriptService.server.ai.behavior.BehaviorWrapper)
local ConfrontTrespasser = require(ServerScriptService.server.ai.behavior.ConfrontTrespasser)
local EquipWeaponOnFled = require(ServerScriptService.server.ai.behavior.EquipWeaponOnFled)
local FleeToEscapePoints = require(ServerScriptService.server.ai.behavior.FleeToEscapePoints)
local GuardPanic = require(ServerScriptService.server.ai.behavior.GuardPanic)
local KillTarget = require(ServerScriptService.server.ai.behavior.KillTarget)
local LookAndFaceAtTargetSink = require(ServerScriptService.server.ai.behavior.LookAndFaceAtTargetSink)
local LookAtSuspiciousPlayer = require(ServerScriptService.server.ai.behavior.LookAtSuspiciousPlayer)
local PleaForMercy = require(ServerScriptService.server.ai.behavior.PleaForMercy)
local SetIsCuriousMemory = require(ServerScriptService.server.ai.behavior.SetIsCuriousMemory)
local SetPanicFace = require(ServerScriptService.server.ai.behavior.SetPanicFace)
local ValidateTrespasser = require(ServerScriptService.server.ai.behavior.ValidateTrespasser)
local WalkToRandomPost = require(ServerScriptService.server.ai.behavior.WalkToRandomPost)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local SensorTypes = require(ServerScriptService.server.ai.sensing.SensorTypes)

local GuardAi = {}

type Agent = Agent.Agent
type Brain<T> = Brain.Brain<T>

local MEMORY_TYPES = {
	MemoryModuleTypes.LOOK_TARGET,
	MemoryModuleTypes.KILL_TARGET,
	MemoryModuleTypes.PANIC_PLAYER_SOURCE,
	MemoryModuleTypes.IS_CURIOUS,
	MemoryModuleTypes.IS_PANICKING,
	MemoryModuleTypes.IS_FLEEING,
	MemoryModuleTypes.DESIGNATED_POSTS,
	MemoryModuleTypes.PATROL_STATE,
	MemoryModuleTypes.TARGET_POST,
	MemoryModuleTypes.POST_VACATE_COOLDOWN,
	MemoryModuleTypes.CONFRONTING_TRESPASSER,
	MemoryModuleTypes.PANIC_POSITION,
	MemoryModuleTypes.HAS_FLED
}

local SENSOR_TYPES = {
	SensorTypes.VISIBLE_PLAYERS_SENSOR,
	SensorTypes.HEARING_PLAYERS_SENSOR
}

function GuardAi.makeBrain(guard: Agent)
	local brain = Brain.new(guard, MEMORY_TYPES, SENSOR_TYPES)
	GuardAi.initCoreActivity(brain)
	GuardAi.initWorkActivity(brain)
	GuardAi.initPanicActivity(brain)
	GuardAi.initConfrontActivity(brain)
	brain:setNullableMemory(MemoryModuleTypes.DESIGNATED_POSTS, guard.designatedPosts)
	brain:setCoreActivities({Activity.CORE})
	brain:setDefaultActivity(Activity.IDLE)
	brain:useDefaultActivity()
	return brain
end

function GuardAi.initCoreActivity(brain: Brain<Agent>): ()
	brain:addActivity(Activity.CORE, 1, {
		BehaviorWrapper.new(LookAndFaceAtTargetSink.new()),
		BehaviorWrapper.new(SetIsCuriousMemory.new()),
		BehaviorWrapper.new(LookAtSuspiciousPlayer.new()),
		BehaviorWrapper.new(GuardPanic.new()),
		BehaviorWrapper.new(ValidateTrespasser.new())
	})
end

function GuardAi.initWorkActivity(brain: Brain<Agent>): ()
	brain:addActivityWithConditions(Activity.WORK, 3, {
		BehaviorWrapper.new(WalkToRandomPost.new()),
	}, {
		[MemoryModuleTypes.CONFRONTING_TRESPASSER] = MemoryStatus.VALUE_ABSENT,
		[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT
	})
end

function GuardAi.initPanicActivity(brain: Brain<Agent>): ()
	brain:addActivityWithConditions(Activity.PANIC, 0, {
		BehaviorWrapper.new(SetPanicFace.new()),
		BehaviorWrapper.new(FleeToEscapePoints.new()),
		--BehaviorWrapper.new(EquipWeaponOnFled.new()),
		BehaviorWrapper.new(KillTarget.new()),
		BehaviorWrapper.new(PleaForMercy.new())
	}, {
		[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_PRESENT
	})
end

function GuardAi.initConfrontActivity(brain: Brain<Agent>): ()
	brain:addActivityWithConditions(Activity.CONFRONT, 2, {
		BehaviorWrapper.new(ConfrontTrespasser.new()),
	}, {
		[MemoryModuleTypes.IS_PANICKING] = MemoryStatus.VALUE_ABSENT,
		[MemoryModuleTypes.CONFRONTING_TRESPASSER] = MemoryStatus.VALUE_PRESENT,
	})
end

function GuardAi.updateActivity(guard: Agent): ()
	guard:getBrain():setActiveActivityToFirstValid({
		Activity.PANIC, Activity.CONFRONT, Activity.WORK
	})
end

return GuardAi