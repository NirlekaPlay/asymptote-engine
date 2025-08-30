--!strict

local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local GuardAi = require(script.Parent.GuardAi)
local Agent = require(ServerScriptService.server.Agent)
local Brain = require(ServerScriptService.server.ai.Brain)
local AnimationControl = require(ServerScriptService.server.ai.control.AnimationControl)
local BodyRotationControl = require(ServerScriptService.server.ai.control.BodyRotationControl)
local BubbleChatControl = require(ServerScriptService.server.ai.control.BubbleChatControl)
local FaceControl = require(ServerScriptService.server.ai.control.FaceControl)
local GunControl = require(ServerScriptService.server.ai.control.GunControl)
local LookControl = require(ServerScriptService.server.ai.control.LookControl)
local RagdollControl = require(ServerScriptService.server.ai.control.RagdollControl)
local ReportControl = require(ServerScriptService.server.ai.control.ReportControl)
local TalkControl = require(ServerScriptService.server.ai.control.TalkControl)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)

local DEFAULT_CAN_DETECT_THROUGH_DISGUISES = false
local DEFAULT_CAN_BE_INTIMIDATED = false
local DEFAULT_SIGHT_RADIUS = 50
local DEFAULT_HEARING_RADIUS = 10
local DEFAULT_PERIPH_VISION_ANGLE = 180

local Guard = {}
Guard.__index = Guard

export type Guard = typeof(setmetatable({} :: {
	uuid: string,
	character: Model,
	alive: boolean,
	brain: Brain.Brain<Agent.Agent>,
	bodyRotationControl: BodyRotationControl.BodyRotationControl,
	gunControl: GunControl.GunControl,
	lookControl: LookControl.LookControl,
	faceControl: FaceControl.FaceControl,
	bubbleChatControl: BubbleChatControl.BubbleChatControl,
	talkControl: TalkControl.TalkControl,
	reportControl: ReportControl.ReportControl,
	pathNavigation: PathNavigation.PathNavigation,
	suspicionManager: SuspicionManagement.SuspicionManagement,
	designatedPosts: { GuardPost.GuardPost },
	random: Random
}, Guard))

function Guard.new(character: Model, designatedPosts: { GuardPost.GuardPost }): Guard
	local self = setmetatable({}, Guard)

	self.character = character
	self.alive = true
	self.pathNavigation = PathNavigation.new(character, {
		AgentRadius = 2,
		AgentHeight = 2,
		AgentCanJump = false
	})
	self.bodyRotationControl = BodyRotationControl.new(character, self.pathNavigation)
	self.suspicionManager = SuspicionManagement.new(self)
	self.designatedPosts = designatedPosts
	self.animationControl = AnimationControl.new(self)
	self.gunControl = GunControl.new(self)
	self.lookControl = LookControl.new(character)
	self.faceControl = FaceControl.new(character)
	self.faceControl:setFace("Neutral")
	self.bubbleChatControl = BubbleChatControl.new(character)
	self.talkControl = TalkControl.new(character, self.bubbleChatControl)
	self.ragdollControl = RagdollControl.new(character)
	self.reportControl = ReportControl.new(self)
	self.random = Random.new(tick())

	local humanoid = self.character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local humanoidDiedConnection: RBXScriptConnection? = humanoid.Died:Once(function()
		self.alive = false
		self:onDied()
	end)

	self.uuid = HttpService:GenerateGUID(false)
	self.brain = GuardAi.makeBrain(self)

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "NonCollideWithPlayer"
		end
	end

	local descendantAddedConnection = character.DescendantAdded:Connect(function(inst)
		-- make the Agent not collide with players
		-- exclude "RagdollColliderPart" as those are ragdoll parts.
		-- making them not have collision will result in weird looking ragdolls.
		if inst:IsA("BasePart") and inst.Name ~= "RagdollColliderPart" then
			inst.CollisionGroup = "NonCollideWithPlayer"
		end
	end)

	character.Destroying:Once(function()
		if humanoidDiedConnection then
			humanoidDiedConnection:Disconnect()
			humanoidDiedConnection = nil
		end
		descendantAddedConnection:Disconnect()
	end)

	return self
end

function Guard.update(self: Guard, deltaTime: number): ()
	if not self:isAlive() then
		return
	end

	self.suspicionManager:update(deltaTime)
	self.brain:update(deltaTime)
	GuardAi.updateActivity(self)
	self.bodyRotationControl:update(deltaTime)
	self.lookControl:update(deltaTime)
	self.reportControl:update(deltaTime)
end

function Guard.canDetectThroughDisguises(self: Guard): boolean
	return (self.character:GetAttribute("CanSeeThroughDisguises") :: boolean?) or DEFAULT_CAN_DETECT_THROUGH_DISGUISES
end

function Guard.canBeIntimidated(self: Guard): boolean
	return (self.character:GetAttribute("CanBeIntimidated") :: boolean?) or DEFAULT_CAN_BE_INTIMIDATED
end

function Guard.onDied(self: Guard)
	self.faceControl:setFace("Unconscious")
end

function Guard.isAlive(self: Guard): boolean
	return self.alive
end

function Guard.getCharacterName(self: Guard): string?
	return self.character:GetAttribute("CharName") :: string?
end

function Guard.getBrain(self: Guard): Brain.Brain<Agent.Agent>
	return self.brain
end

function Guard.getGunControl(self: Guard): GunControl.GunControl
	return self.gunControl
end

function Guard.getFaceControl(self: Guard): FaceControl.FaceControl
	return self.faceControl
end

function Guard.getReportControl(self: Guard): ReportControl.ReportControl
	return self.reportControl
end

function Guard.getNavigation(self: Guard): PathNavigation.PathNavigation
	return self.pathNavigation
end

function Guard.getRandom(self: Guard): Random
	return self.random
end

function Guard.getSuspicionManager(self: Guard): SuspicionManagement.SuspicionManagement
	return self.suspicionManager
end

function Guard.getBodyRotationControl(self: Guard): BodyRotationControl.BodyRotationControl
	return self.bodyRotationControl
end

function Guard.getLookControl(self: Guard): LookControl.LookControl
	return self.lookControl
end

function Guard.getBubbleChatControl(self: Guard): BubbleChatControl.BubbleChatControl
	return self.bubbleChatControl
end

function Guard.getTalkControl(self: Guard): TalkControl.TalkControl
	return self.talkControl
end

function Guard.getPrimaryPart(self: Guard): BasePart
	return self.character.PrimaryPart :: BasePart
end

--

function Guard.getSightRadius(self: Guard): number
	return (self.character:GetAttribute("SightRadius") :: number?) or DEFAULT_SIGHT_RADIUS
end

function Guard.getHearingRadius(self: Guard): number
	return (self.character:GetAttribute("HearingRadius") :: number?) or DEFAULT_HEARING_RADIUS
end

function Guard.getPeripheralVisionAngle(self: Guard): number
	return (self.character:GetAttribute("PeriphAngle") :: number?) or DEFAULT_PERIPH_VISION_ANGLE
end

--

function Guard.getUuid(self: Guard)
	return self.uuid
end

return Guard