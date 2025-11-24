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
local ReportControl = require(ServerScriptService.server.ai.control.ReportControl)
local TalkControl = require(ServerScriptService.server.ai.control.TalkControl)
local DetectionManagement = require(ServerScriptService.server.ai.detection.DetectionManagement)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local Node = require(ServerScriptService.server.ai.navigation.Node)
local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)

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
	character: Model & { Humanoid: Humanoid },
	alive: boolean,
	brain: Brain.Brain<any>,
	bodyRotationControl: BodyRotationControl.BodyRotationControl,
	bubbleChatControl: BubbleChatControl.BubbleChatControl,
	gunControl: GunControl.GunControl,
	talkControl: TalkControl.TalkControl,
	lookControl: LookControl.LookControl,
	faceControl: FaceControl.FaceControl,
	reportControl: ReportControl.ReportControl,
	pathNavigation: PathNavigation.PathNavigation,
	random: Random,
	detectionManager: DetectionManagement.DetectionManagement,
	--
	designatedPosts: { Node.Node },
	enforceClass: { [string]: number }
}, DummyAgent))

function DummyAgent.new(serverLevel: ServerLevel.ServerLevel, character: Model, charName: string?, seed: number?): DummyAgent
	local self = setmetatable({}, DummyAgent)

	self.character = character
	self.characterName = charName or ""
	self.alive = true
	self.pathNavigation = PathNavigation.new(character, {
		AgentRadius = 2,
		AgentHeight = 2,
		AgentCanJump = false,
		WaypointSpacing = 1
	})
	self.detectionManager = DetectionManagement.new(self)
	self.lookControl = LookControl.new(character)
	self.faceControl = FaceControl.new(character)
	self.faceControl:setFace("Neutral")
	self.bodyRotationControl = BodyRotationControl.new(character, self.pathNavigation)
	self.bubbleChatControl = BubbleChatControl.new(character)
	self.gunControl = GunControl.new(self, serverLevel)
	self.talkControl = TalkControl.new(character, self.bubbleChatControl, self.faceControl)
	self.ragdollControl = RagdollControl.new(character)
	self.reportControl = ReportControl.new(self, serverLevel)
	self.random = Random.new(seed or tick())

	local humanoid = self.character:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.JumpHeight = 0
	humanoid.JumpPower = 0
	local humanoidDiedConnection: RBXScriptConnection? = humanoid.Died:Once(function()
		self:onDied()
	end)

	self.uuid = HttpService:GenerateGUID(false)
	self.brain = DetectionDummyAi.makeBrain(self) :: Brain.Brain<any>
	self.designatedPosts = {} :: { Node.Node }
	self.enforceClass = {}

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = CollisionGroupTypes.NON_COLLIDE_WITH_PLAYER
		end
	end

	-- TODO: Legacy. Fix the Animate script.
	local isPathfindingBoolValue = Instance.new("BoolValue")
	isPathfindingBoolValue.Name = "isPathfinding"
	isPathfindingBoolValue.Value = false
	isPathfindingBoolValue.Parent = character

	local isRunning = Instance.new("BoolValue")
	isRunning.Name = "isRunning"
	isRunning.Value = false
	isRunning.Parent = character

	local isGuarding = Instance.new("BoolValue")
	isGuarding.Name = "isGuarding"
	isGuarding.Value = false
	isGuarding.Parent = character

	local isReporting = Instance.new("BoolValue")
	isReporting.Name = "isReporting"
	isReporting.Value = false
	isReporting.Parent = character

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

	serverLevel:getPersistentInstanceManager():register(character)

	return self
end

function DummyAgent.setDesignatedPosts(self: DummyAgent, posts: { Node.Node }): DummyAgent
	self.designatedPosts = posts
	self.brain:setNullableMemory(MemoryModuleTypes.DESIGNATED_POSTS, posts)
	return self
end

function DummyAgent.setEnforceClass(self: DummyAgent, enforceClass: { [string]: number }): DummyAgent
	self.enforceClass = enforceClass
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
	self.reportControl:update(deltaTime)

	-- TODO: Legacy walking animation code.
	if self.pathNavigation.pathfinder.Status == "Active" then
		self.character.isPathfinding.Value = true
		if self.character.Humanoid.WalkSpeed >= 18 then
			self.character.isRunning.Value = true
		else
			self.character.isRunning.Value = false
		end
	else
		self.character.isPathfinding.Value = false
		self.character.isRunning.Value = false
	end
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

function DummyAgent.getReportControl(self: DummyAgent): ReportControl.ReportControl
	return self.reportControl
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