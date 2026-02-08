--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Agent = require(ServerScriptService.server.Agent)
local Brain = require(ServerScriptService.server.ai.Brain)
local DetectableEntity = require(ServerScriptService.server.ai.detection.entity.DetectableEntity)
local DetectionManager = require(ServerScriptService.server.ai.detection.DetectionManager)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local SensorFactories = require(ServerScriptService.server.ai.sensing.SensorFactories)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local EntityUtils = require(ServerScriptService.server.entity.util.EntityUtils)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

local DUMMY_RIG = ReplicatedStorage.shared.assets.characters.Rig

---------------------------------------------------------------------------------------------------
-- GameTestHelper
---------------------------------------------------------------------------------------------------

local GameTestHelper = {}
GameTestHelper.__index = GameTestHelper

export type GameTestHelper = typeof(setmetatable({} :: {
}, GameTestHelper))

function GameTestHelper.new(): GameTestHelper
	return setmetatable({}, GameTestHelper)
end

function GameTestHelper.spawnDummyCharacter(self: GameTestHelper): Model
	local cloned = DUMMY_RIG:Clone()
	cloned.Parent = workspace
	return cloned
end

function GameTestHelper.spawnDummyCharacterAt(self: GameTestHelper, position: Vector3): Model
	local characterRigClone = self:spawnDummyCharacter()
	characterRigClone:PivotTo(CFrame.new(position))
	return characterRigClone
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- DetectionDummyTests
---------------------------------------------------------------------------------------------------

local DEFAULT_SIGHT_RADIUS = 50
local DEFAULT_HEARING_RADIUS = 10
local DEFAULT_PERIPH_VISION_ANGLE = 180

local detectableEntitiesRegistry: { [DetectableEntity.DetectableEntity]: true } = {}

--

local function isValidPlayer(player: Player): boolean
	local playerStatusHolder = PlayerStatusRegistry.getPlayerStatusHolder(player)
	if not playerStatusHolder then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart or not humanoidRootPart:IsA("BasePart") then
		return false
	end

	return true
end

local function isValidPlayerFromEntityUuid(uuid: string): boolean
	local entity = EntityManager.getEntityByUuid(uuid)
	if not entity then
		return false
	end

	local player = EntityUtils.ifPlayerThenGet(entity)
	if not player then
		return false
	end

	return isValidPlayer(player)
end

local function isValidPlayerFromEntity(entity: EntityManager.DynamicEntity | EntityManager.StaticEntity): boolean
	local player = EntityUtils.ifPlayerThenGet(entity)
	if not player then
		return false
	end

	return isValidPlayer(player)
end

--

local function getOrCreateDetectableEntityFromUuid(uuid: string): DetectableEntity.DetectableEntity

end

local function getPerceivedDetectableEntities(agent: Agent.Agent): { DetectableEntity.DetectableEntity }
	local visibleEntities = agent:getBrain():getMemory(MemoryModuleTypes.VISIBLE_ENTITIES):orElse({})
	local hearablePlayers = agent:getBrain():getMemory(MemoryModuleTypes.HEARABLE_PLAYERS):orElse({})

	local perceivedEntities: { [string]: { isVisible: boolean?, isHeard: boolean? } } = {}

	for uuid in visibleEntities :: { [string]: true } do
		local entity = EntityManager.getEntityByUuid(uuid)
		if not entity then
			continue
		end
		
		if EntityUtils.isPlayer(entity) then
			if not isValidPlayerFromEntity(entity) then
				continue
			end
		end

		if not perceivedEntities[uuid] then
			perceivedEntities[uuid] = {}
		end

		perceivedEntities[uuid].isVisible = true
	end

	for player in hearablePlayers :: { [Player]: true } do
		local uuid = tostring(player.UserId)
		if not isValidPlayerFromEntityUuid(uuid) then
			continue
		end

		if not perceivedEntities[uuid] then
			perceivedEntities[uuid] = {}
		end

		perceivedEntities[uuid].isHeard = true
	end

	print(perceivedEntities)
end

local DetectionDummyTests = {}

function DetectionDummyTests.testDummyDetection(helper: GameTestHelper): ()
	local dummy1 = helper:spawnDummyCharacter()
	local dummy2 = helper:spawnDummyCharacterAt(Vector3.new(10, 0, 10))

	local Agent = {}
	Agent.__index = Agent

	function Agent.new(char: Model): Agent.Agent
		return setmetatable({
			character = char
		}, Agent)
	end

	function Agent.getPrimaryPart(self: Agent.Agent): BasePart
		return self.character.PrimaryPart :: BasePart
	end

	function Agent.getBrain(self: Agent.Agent): Brain.Brain<Agent.Agent>
		return self.brain
	end
	
	function Agent.update(self: Agent.Agent, deltaTime: number): ()
		local brain = self:getBrain()
		brain:update(deltaTime)
		local detectionManager = self.detectionManager
		local perceivedEntities = getPerceivedDetectableEntities(self)
	end

	function Agent.getSightRadius(self: Agent.Agent): number
		return (self.character:GetAttribute("SightRadius") :: number?) or DEFAULT_SIGHT_RADIUS
	end

	function Agent.getHearingRadius(self: Agent.Agent): number
		return (self.character:GetAttribute("HearingRadius") :: number?) or DEFAULT_HEARING_RADIUS
	end

	function Agent.getPeripheralVisionAngle(self: Agent.Agent): number
		return (self.character:GetAttribute("PeriphAngle") :: number?) or DEFAULT_PERIPH_VISION_ANGLE
	end

	local dummy1Agent = Agent.new(dummy2)
	dummy1Agent.detectionManager = DetectionManager.new(dummy1Agent)
	dummy1Agent.brain = Brain.new(dummy1Agent, {}, {SensorFactories.VISIBLE_ENTITIES_SENSOR, SensorFactories.HEARING_PLAYERS_SENSOR})

	-- You should call this entire function once anyway
	RunService.PreSimulation:Connect(function(deltaTime)
		dummy1Agent:update(deltaTime)
	end)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

local function proccessPlayer(player: Player): ()
	local uuid = tostring(player.UserId)
	EntityManager.newDynamic("Player", player, uuid)
end

Players.PlayerAdded:Connect(proccessPlayer)

for _, player in Players:GetPlayers() do
	proccessPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	local uuid = tostring(player.UserId)
	EntityManager.Entities[uuid] = nil
end)

DetectionDummyTests.testDummyDetection(GameTestHelper.new())

return DetectionDummyTests