--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Agent = require(ServerScriptService.server.Agent)
local PerceptiveAgent = require(ServerScriptService.server.PerceptiveAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)

local DEBUG_RAYCAST = false
local DEBUG_RAYCAST_LIFETIME = 1 / 20
local RAY_PENETRATION_DEPTH = 0.01
local VISIBILITY_THRESHOLD = 0.3
local MAX_ITERATIONS = 10
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
	if not agentPrimaryPart then return false end

	local agentPos = agentPrimaryPart.Position
	local entityInstance: Instance
	local entityPos

	-- Determine entity's main reference position and instance
	if entity.instance:IsA("BasePart") then
		entityPos = entity.instance.Position
		entityInstance = entity.instance
	elseif entity.instance:IsA("Model") then
		if not entity.instance.PrimaryPart then return false end
		entityPos = entity.instance.PrimaryPart.Position
		entityInstance = entity.instance.PrimaryPart
	elseif entity.name == "Player" then
		if not (entity.instance and entity.instance:IsA("Player") and entity.instance.Character and entity.instance.Character.PrimaryPart) then
			return false
		end
		entityPos = entity.instance.Character.PrimaryPart.Position
		entityInstance = entity.instance.Character
	else
		return false
	end

	if not entityPos or not entityInstance then return false end

	-- Basic distance and vision cone checks
	local diff = entityPos - agentPos
	local dist = diff.Magnitude
	if dist > agent:getSightRadius() then return false end

	local dot = agentPrimaryPart.CFrame.LookVector:Dot(diff.Unit)
	local cosHalfAngle = math.cos(math.rad(agent:getPeripheralVisionAngle() / 2))
	if dot < cosHalfAngle then return false end

	-- Initialize raycast parameters
	local rayParams = self.rayParams
	if not rayParams then
		rayParams = RaycastParams.new()
		rayParams.CollisionGroup = CollisionGroupTypes.NPC_VISION_RAY
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { agent.character }
		rayParams.CollisionGroup = CollisionGroupTypes.VISION_RAYCAST
		self.rayParams = rayParams
	end

	-- Perform multi-pass raycast with transparency handling
	local direction = diff.Unit * agent:getSightRadius()
	local origin = agentPos
	local remainingTransparency = 1.0

	for _ = 1, MAX_ITERATIONS do
		local rayResult = workspace:Raycast(origin, direction, rayParams)

		if not rayResult then
			if DEBUG_RAYCAST then
				Debris:AddItem(Draw.ray(Ray.new(origin, direction), GREEN), DEBUG_RAYCAST_LIFETIME)
			end
			return true
		end

		if rayResult.Instance.CollisionGroup == CollisionGroupTypes.BLOCK_VISION_RAYCAST then
			if DEBUG_RAYCAST then
				Debris:AddItem(Draw.line(agentPos, rayResult.Position, RED), DEBUG_RAYCAST_LIFETIME)
			end
			return false
		end

		local hitPart = rayResult.Instance
		local hitTransparency = hitPart.Transparency

		if (hitPart == entityInstance :: BasePart) or hitPart:IsDescendantOf(entityInstance :: Instance) then
			if DEBUG_RAYCAST then
				Debris:AddItem(Draw.line(agentPos, entityPos, GREEN), DEBUG_RAYCAST_LIFETIME)
			end
			return remainingTransparency > VISIBILITY_THRESHOLD
		end

		if hitTransparency > 0 then
			remainingTransparency = remainingTransparency * (1 - (hitTransparency * 0.7))
			
			origin = rayResult.Position + direction.Unit * RAY_PENETRATION_DEPTH
			
			local newFilter = table.clone(rayParams.FilterDescendantsInstances)
			table.insert(newFilter, hitPart)
			rayParams.FilterDescendantsInstances = newFilter

			if remainingTransparency <= VISIBILITY_THRESHOLD then
				if DEBUG_RAYCAST then
					Debris:AddItem(Draw.line(agentPos, rayResult.Position, ORANGE), DEBUG_RAYCAST_LIFETIME)
				end
				return false
			end
		else
			if DEBUG_RAYCAST then
				Debris:AddItem(Draw.line(agentPos, rayResult.Position, RED), DEBUG_RAYCAST_LIFETIME)
			end
			return false
		end
	end

	return false
end

return VisibleEntitiesSensor