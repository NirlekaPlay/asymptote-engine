--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local ArmedAgent = require(ServerScriptService.server.ArmedAgent)
local ReporterAgent = require(ServerScriptService.server.ReporterAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local MemoryStatus = require(ServerScriptService.server.ai.memory.MemoryStatus)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)

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
type Agent = Agent.Agent & ArmedAgent.ArmedAgent & ReporterAgent.ReporterAgent

function KillTarget.new(): KillTarget
	return setmetatable({
		minDuration = math.huge,
		maxDuration = math.huge,
		triggerFingerCooldown = 0.5,
		targetHumanoidDiedConnection = nil :: RBXScriptConnection?,
		selfHumanoidDiedConnection = nil :: RBXScriptConnection?
	}, KillTarget)
end

local MEMORY_REQUIREMENTS = {
	[MemoryModuleTypes.KILL_TARGET] = MemoryStatus.VALUE_PRESENT
}

function KillTarget.getMemoryRequirements(self: KillTarget): { [MemoryModuleType<any>]: MemoryStatus }
	return MEMORY_REQUIREMENTS
end

function KillTarget.checkExtraStartConditions(self: KillTarget, agent: Agent): boolean
	return not agent:getReportControl():isReporting()
end

function KillTarget.canStillUse(self: KillTarget, agent: Agent): boolean
	local brain = agent:getBrain()
	local killTarget = brain:getMemory(MemoryModuleTypes.KILL_TARGET)
	local visibleEntities = brain:getMemory(MemoryModuleTypes.VISIBLE_ENTITIES):orElse({})
	local hearingPlayers = brain:getMemory(MemoryModuleTypes.HEARABLE_PLAYERS):orElse({})

	local result = killTarget:map(function(player) return tostring(player.UserId) end)
		:map(function(targetUuid)
			if visibleEntities[targetUuid] ~= nil then
				return true
			end

			local entityObj = EntityManager.getEntityByUuid(targetUuid)
			if entityObj and not entityObj.isStatic and entityObj.name == "Player" then
				return hearingPlayers[entityObj.instance :: Player] ~= nil
			end

			return false
		end)
		:orElse(false) :: boolean

	return result
end

function KillTarget.doStart(self: KillTarget, agent: Agent): ()
	agent.character:FindFirstChildOfClass("Humanoid").AutoRotate = false
	agent:getGunControl():equipGun({
		roundsInMagazine = 0,
		magazineRoundsCapacity = 30,
		fireDelay = 0.15
	})

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
	agent.character:FindFirstChildOfClass("Humanoid").AutoRotate = false
	self.triggerFingerCooldown = math.random(10, 40) / 100
	if self.targetHumanoidDiedConnection then
		self.targetHumanoidDiedConnection:Disconnect()
		self.targetHumanoidDiedConnection = nil
	end
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

	if agent:getGunControl():hasRanOutOfAmmo() then
		agent:getFaceControl():setFace("Shocked")
		agent:getTalkControl():sayRandomSequences({
			{"Shrimp! Im out of ammo!", "I surrender!"},
			{"Awh come on! Im out!", " I ran out of ammo!", "Please! Have mercy!"},
			{"Im out!", "Aghh!", "I cant do anything!"},
			{"On Envvy's green earth!", "Im out of ammo!", "Please!", "I surrender!"}
		})
		agent:getGunControl():drop()
		agent:getBrain():eraseMemory(MemoryModuleTypes.KILL_TARGET)
		agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_PANICKING, true)
		agent:getBrain():setNullableMemory(MemoryModuleTypes.IS_INTIMIDATED, true)
		return
	end

	if self.triggerFingerCooldown <= 0 then
		agent:getGunControl():shoot(killTarget.Character.HumanoidRootPart.Position)
	else
		self.triggerFingerCooldown -= deltaTime
		if self.triggerFingerCooldown <= 0 then
			agent:getTalkControl():sayRandomSequences({
				{"Why won't you die?!?!"},
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