--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)

--[=[
	@class KillTarget
]=]
local KillTarget = {}
KillTarget.__index = KillTarget
KillTarget.ClassName = "KillTarget"

export type KillTarget = typeof(setmetatable({} :: {
	triggerFingerCooldown: number,
	targetHumanoidDiedConnection: RBXScriptConnection?,
	selfHumanoidDiedConnection: RBXScriptConnection?
}, KillTarget))

type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>
type MemoryStatus = MemoryStatus.MemoryStatus
type Agent = Agent.Agent & ArmedAgent.ArmedAgent

function KillTarget.new(): KillTarget
	return setmetatable({
		minDuration = math.huge,
		maxDuration = math.huge,
		triggerFingerCooldown = 0.5,
		targetHumanoidDiedConnection = nil,
		selfHumanoidDiedConnection = nil
	}, KillTarget)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.KILL_TARGET] = MemoryStatus.VALUE_PRESENT
}

function KillTarget.getMemoryRequirements(self: KillTarget): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function KillTarget.checkExtraStartConditions(self: KillTarget, agent: Agent): boolean
	return true
end

function KillTarget.canStillUse(self: KillTarget, agent: Agent): boolean
	local brain = agent:getBrain()
	local killTarget = brain:getMemory(MemoryModuleTypes.KILL_TARGET)
	-- stolen from LookAndFaceAtTargetSink
	return killTarget
		:flatMap(function(targetPlayer)
			return brain:getMemory(MemoryModuleTypes.VISIBLE_PLAYERS)
				:map(function(visible)
					return visible[targetPlayer]
			end)
		end)
		:isPresent() or killTarget
		:flatMap(function(targetPlayer)
				return brain:getMemory(MemoryModuleTypes.HEARABLE_PLAYERS)
					:map(function(hearable)
						return hearable[targetPlayer]
			end)
		end)
		:isPresent()
end

function KillTarget.doStart(self: KillTarget, agent: Agent): ()
	agent:getGunControl():equipGun({
		roundsInMagazine = 0,
		magazineRoundsCapacity = 30,
		fireDelay = 0.15
	})
	agent:getGunControl():reload()
	agent.character:SetAttribute("HearingRadius", 30)

	if not self.selfHumanoidDiedConnection then
		self.selfHumanoidDiedConnection = agent.character:FindFirstChildOfClass("Humanoid").Died:Once(function()
			if self.targetHumanoidDiedConnection then
				self.targetHumanoidDiedConnection:Disconnect()
				self.targetHumanoidDiedConnection = nil
			end
		end)
	end
end

function KillTarget.doStop(self: KillTarget, agent: Agent): ()
	self.triggerFingerCooldown = 0.5
	--agent:getGunControl():unequipGun()
end

function KillTarget.doUpdate(self: KillTarget, agent: Agent, deltaTime: number): ()
	local brain = agent:getBrain()
	local killTarget = brain:getMemory(MemoryModuleTypes.KILL_TARGET):get()

	if not killTarget.Character then
		return
	end

	local humanoid = killTarget.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	agent:getGunControl():lookAt(killTarget.Character.PrimaryPart.Position)
	agent:getBodyRotationControl():setRotateTowards(killTarget.Character.PrimaryPart.Position)

	if humanoid.Health <= 0 then
		return
	end

	if self.triggerFingerCooldown <= 0 then
		agent:getGunControl():shoot(killTarget.Character.HumanoidRootPart.Position)
	else
		self.triggerFingerCooldown -= deltaTime
		if self.triggerFingerCooldown <= 0 then
			agent:getTalkControl():sayRandomSequences({
				{"Why won't you die?!?!"},
				{"Oh, respawning's a thing?", "Good!", "Means I can do this over and over!!"},
				{"Let's make this quick—!", "I've got paperwork after this!!"},
			})
		end
	end

	if not self.targetHumanoidDiedConnection then
		self.targetHumanoidDiedConnection = humanoid.Died:Once(function()
			if not agent then
				return
			end

			agent:getTalkControl():sayRandomSequences({
				{"You'll be back!", "You *always* come back!", "I can work with that!"},
				{"You can't just die that easily!"}
			})
			self.targetHumanoidDiedConnection = nil
		end)
	end
end

return KillTarget