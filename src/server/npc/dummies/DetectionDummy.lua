--!strict

local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local DetectionDummyAi = require(script.Parent.DetectionDummyAi)
local Brain = require(ServerScriptService.server.ai.Brain)
local BodyRotationControl = require(ServerScriptService.server.ai.control.BodyRotationControl)
local BubbleChatControl = require(ServerScriptService.server.ai.control.BubbleChatControl)
local FaceControl = require(ServerScriptService.server.ai.control.FaceControl)
local GunControl = require(ServerScriptService.server.ai.control.GunControl)
local LookControl = require(ServerScriptService.server.ai.control.LookControl)
local RagdollControl = require(ServerScriptService.server.ai.control.RagdollControl)
local TalkControl = require(ServerScriptService.server.ai.control.TalkControl)
local DetectionManagement = require(ServerScriptService.server.ai.detection.DetectionManagement)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)

local DEFAULT_SIGHT_RADIUS = 50
local DEFAULT_HEARING_RADIUS = 10
local DEFAULT_PERIPH_VISION_ANGLE = 180

--[=[
	@class DummyAgent

	An abstract DummyAgent. Detect C4 prototype idfk
]=]
local DummyAgent = {}
DummyAgent.__index = DummyAgent

export type DummyAgent = typeof(setmetatable({} :: {
	uuid: string,
	characterName: string,
	character: Model,
	alive: boolean,
	brain: Brain.Brain<any>,
	bodyRotationControl: BodyRotationControl.BodyRotationControl,
	bubbleChatControl: BubbleChatControl.BubbleChatControl,
	gunControl: GunControl.GunControl,
	talkControl: TalkControl.TalkControl,
	lookControl: LookControl.LookControl,
	faceControl: FaceControl.FaceControl,
	pathNavigation: PathNavigation.PathNavigation,
	random: Random,
	detectionManager: DetectionManagement.DetectionManagement,
	--
	designatedPosts: { GuardPost.GuardPost }
}, DummyAgent))

function DummyAgent.new(character: Model): DummyAgent
	local self = setmetatable({}, DummyAgent)

	self.character = character
	self.alive = true
	self.pathNavigation = PathNavigation.new(character, {
		AgentRadius = 2,
		AgentHeight = 2,
		AgentCanJump = true,
		WaypointSpacing = 1
	})
	self.detectionManager = DetectionManagement.new(self)
	self.lookControl = LookControl.new(character)
	self.faceControl = FaceControl.new(character)
	self.faceControl:setFace("Neutral")
	self.bodyRotationControl = BodyRotationControl.new(character, self.pathNavigation)
	self.bubbleChatControl = BubbleChatControl.new(character)
	self.gunControl = GunControl.new(self)
	self.talkControl = TalkControl.new(character, self.bubbleChatControl)
	self.ragdollControl = RagdollControl.new(character)
	self.random = Random.new(tick())

	local humanoid = self.character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local humanoidDiedConnection: RBXScriptConnection? = humanoid.Died:Once(function()
		self:onDied()
	end)

	self.uuid = HttpService:GenerateGUID(false)
	self.brain = DetectionDummyAi.makeBrain(self) :: Brain.Brain<any>
	self.designatedPosts = {} :: { GuardPost.GuardPost }

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER
		end
	end

	local descendantAddedConnection = character.DescendantAdded:Connect(function(inst)
		-- make the Agent not collide with players
		-- exclude "RagdollColliderPart" as those are ragdoll parts.
		-- making them not have collision will result in weird looking ragdolls.
		if inst:IsA("BasePart") and inst.Name ~= RagdollControl.RAGDOLL_COLLIDER_PART_NAME then
			inst.CollisionGroup = CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER
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

function DummyAgent.setDesignatedPosts(self: DummyAgent, posts: { GuardPost.GuardPost }): DummyAgent
	self.designatedPosts = posts
	self.brain:setNullableMemory(MemoryModuleTypes.DESIGNATED_POSTS, posts)
	return self
end

function DummyAgent.update(self: DummyAgent, deltaTime: number): ()
	-- Breaks SRP. But who cares at this point.
	local visibleEntities = self.brain:getMemory(MemoryModuleTypes.VISIBLE_ENTITIES):orElse({})
	local hearingPlayers = self.brain:getMemory(MemoryModuleTypes.HEARABLE_PLAYERS):orElse({})

	local detectionProfiles: { [string]: DetectionManagement.DetectionProfile } = {}

	for entityId, _ in pairs(visibleEntities) do
		detectionProfiles[entityId] = {
			isVisible = true,
			isHeard = false
		}
	end

	for player, _ in pairs(hearingPlayers) do
		-- EntityManager manages Player entities with their Roblox ID instead of a UUID.
		-- Sounds stupid I know, blame Nico later, not me.
		local playerId = tostring(player.UserId)
		if detectionProfiles[playerId] then
			detectionProfiles[playerId].isHeard = true
		else
			detectionProfiles[playerId] = {
				isVisible = false,
				isHeard = true
			}
		end
	end

	self.detectionManager:addOrUpdateDetectedEntities(detectionProfiles)
	self.detectionManager:update(deltaTime)
	DetectionDummyAi.updateActivity(self)
	self.brain:update(deltaTime)
	self.lookControl:update(deltaTime)
	self.bodyRotationControl:update(deltaTime)
end

function DummyAgent.isAlive(self: DummyAgent): boolean
	return self.alive
end

function DummyAgent.canBeIntimidated(self: DummyAgent): boolean
	return true
end

function DummyAgent.canDetectThroughDisguises(self: DummyAgent): boolean
	return false
end

function DummyAgent.getCharacterName(self: DummyAgent): string
	return self.characterName
end

function DummyAgent.getBrain(self: DummyAgent): Brain.Brain<DummyAgent>
	return self.brain
end

function DummyAgent.getFaceControl(self: DummyAgent): FaceControl.FaceControl
	return self.faceControl
end

function DummyAgent.getGunControl(self: DummyAgent): GunControl.GunControl
	return self.gunControl
end

function DummyAgent.getNavigation(self: DummyAgent): PathNavigation.PathNavigation
	return self.pathNavigation
end

function DummyAgent.getRandom(self: DummyAgent): Random
	return self.random
end

function DummyAgent.getUuid(self: DummyAgent): string
	return self.uuid
end

function DummyAgent.getDetectionManager(self: DummyAgent): DetectionManagement.DetectionManagement
	return self.detectionManager
end

function DummyAgent.getBodyRotationControl(self: DummyAgent): BodyRotationControl.BodyRotationControl
	return self.bodyRotationControl
end

function DummyAgent.getLookControl(self: DummyAgent): LookControl.LookControl
	return self.lookControl
end

function DummyAgent.getBubbleChatControl(self: DummyAgent): BubbleChatControl.BubbleChatControl
	return self.bubbleChatControl
end

function DummyAgent.getTalkControl(self: DummyAgent): TalkControl.TalkControl
	return self.talkControl
end

function DummyAgent.getPrimaryPart(self: DummyAgent): BasePart
	return self.character.PrimaryPart :: BasePart
end

--

function DummyAgent.onDied(self: DummyAgent): ()
	self.alive = false
	self:getFaceControl():setFace("Unconscious")
end

--

function DummyAgent.getSightRadius(self: DummyAgent): number
	return (self.character:GetAttribute("SightRadius") :: number?) or DEFAULT_SIGHT_RADIUS
end

function DummyAgent.getHearingRadius(self: DummyAgent): number
	return (self.character:GetAttribute("HearingRadius") :: number?) or DEFAULT_HEARING_RADIUS
end

function DummyAgent.getPeripheralVisionAngle(self: DummyAgent): number
	return (self.character:GetAttribute("PeriphAngle") :: number?) or DEFAULT_PERIPH_VISION_ANGLE
end

return DummyAgent