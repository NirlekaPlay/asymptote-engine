--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Agent = require(ServerScriptService.server.Agent)
local PerceptiveAgent = require(ServerScriptService.server.PerceptiveAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)

local DEBUG_RAYCAST = true
local DEBUG_RAYCAST_LIFETIME = 1 / 20
local RED = Color3.new(1, 0, 0)
local GREEN = Color3.new(0, 1, 0)
local ORANGE = BrickColor.Yellow().Color

local VisibleEntitiesSensor = {}
VisibleEntitiesSensor.__index = VisibleEntitiesSensor

export type VisibleEntitiesSensor = typeof(setmetatable({} :: {
	rayParams: RaycastParams?
}, VisibleEntitiesSensor))

type Agent = Agent.Agent & PerceptiveAgent.PerceptiveAgent

function VisibleEntitiesSensor.new(): VisibleEntitiesSensor
	return setmetatable({
		rayParams = nil :: RaycastParams?
	}, VisibleEntitiesSensor)
end

function VisibleEntitiesSensor.getRequiredMemories(self: VisibleEntitiesSensor): { MemoryModuleTypes.MemoryModuleType<any> }
	return { MemoryModuleTypes.VISIBLE_PLAYERS, MemoryModuleTypes.VISISBLE_C4, MemoryModuleTypes.VISIBLE_ENTITIES }
end

function VisibleEntitiesSensor.getScanRate(self: VisibleEntitiesSensor): number
	return 1 / 20
end

function VisibleEntitiesSensor.doUpdate(self: VisibleEntitiesSensor, agent: Agent, deltaTime: number)
	local visibleEntities = {} :: { [string]: true }
	local visiblePlayers = {} :: { [string]: true }
	local visibleC4 = {} :: { [string]: true }

	for entityUID, entity in pairs(EntityManager.Entities) do
		if entity.isStatic == true then continue end

		local isInVision = self:isInVision(agent, entity :: EntityManager.DynamicEntity)
		if not isInVision then continue end

		if entity.name == "C4" then
			visibleC4[entityUID] = true
		end

		if entity.instance:IsA("Player") then
			visiblePlayers[entityUID] = true
		end

		visibleEntities[entityUID] = true
	end

	agent:getBrain():setNullableMemory(MemoryModuleTypes.VISISBLE_C4, visibleC4)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.VISIBLE_PLAYERS, visiblePlayers)
	agent:getBrain():setNullableMemory(MemoryModuleTypes.VISIBLE_ENTITIES, visibleEntities)
end

function VisibleEntitiesSensor.isInVision(self: VisibleEntitiesSensor, agent: Agent, entity: EntityManager.DynamicEntity): boolean
	local agentPrimaryPart = agent:getPrimaryPart()

	local agentPos = agentPrimaryPart.Position
	local entityInstance: Instance
	local entityPos

	if entity.instance:IsA("BasePart") then
		entityPos = entity.instance.Position
		entityInstance = entity.instance :: BasePart
	elseif entity.instance:IsA("Model") then
		entityPos = (entity.instance.PrimaryPart :: Part).Position
		entityInstance = entity.instance.PrimaryPart :: BasePart
	end

	if entity.name == "Player" then -- c: oh fuck no
		if not entity.instance then return false end
		if not entity.instance:IsA("Player") then return false end
		if not entity.instance.Character then return false end
		if not entity.instance.Character:IsA("Model") then return false end
		if not entity.instance.Character.PrimaryPart then return false end

		entityPos = entity.instance.Character.PrimaryPart.Position
		entityInstance = entity.instance.Character :: Model
	end

	-- this is the first time we have a shitton of checks
	-- in my entire programming career
	-- we will fix that later c:
	-- just DO IT (for now)
	
	if not entityPos then return false end
	if not entityInstance then return false end
	
	local diff = entityPos - agentPos
	local dist = diff.Magnitude
 
	if dist > agent:getSightRadius() then
		return false
	end

	local dot = agentPrimaryPart.CFrame.LookVector:Dot(diff.Unit)

	local cosHalfAngle = math.cos(math.rad(agent:getPeripheralVisionAngle() / 2))
	if dot < cosHalfAngle then
		return false
	end

	local rayParams = self.rayParams
	if not rayParams then
		local newRayParams = RaycastParams.new()
		newRayParams.FilterType = Enum.RaycastFilterType.Exclude
		newRayParams.FilterDescendantsInstances = { agent.character }
		self.rayParams = newRayParams
		rayParams = newRayParams
	end

	local ray = Ray.new(agentPos, diff.Unit * agent:getSightRadius())
	local rayResult = workspace:Raycast(ray.Origin, ray.Direction, rayParams)
	if not rayResult then
		if DEBUG_RAYCAST then
			Debris:AddItem(Draw.ray(ray, RED), DEBUG_RAYCAST_LIFETIME) -->:)
		end
		return false
	end

	-- that fixes it.
	if rayResult.Instance == entityInstance or rayResult.Instance:IsDescendantOf(entityInstance) then
		if DEBUG_RAYCAST then
			Debris:AddItem(Draw.line(ray.Origin, rayResult.Position, GREEN), DEBUG_RAYCAST_LIFETIME)
		end
		return true
	else
		if DEBUG_RAYCAST then
			Debris:AddItem(Draw.line(ray.Origin, rayResult.Position, ORANGE), DEBUG_RAYCAST_LIFETIME)
		end
	end

	return false
end

return VisibleEntitiesSensor