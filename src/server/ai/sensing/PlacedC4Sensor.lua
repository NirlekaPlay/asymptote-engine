--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local PerceptiveAgent = require(ServerScriptService.server.PerceptiveAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local EntityManager = require(ServerScriptService.server.entity.EntityManager)

local PlacedC4sSensor = {}
PlacedC4sSensor.__index = PlacedC4sSensor

export type PlacedC4sSensor = typeof(setmetatable({} :: {
	rayParams: RaycastParams?
}, PlacedC4sSensor))

type Agent = Agent.Agent & PerceptiveAgent.PerceptiveAgent -- the agent type idk

function PlacedC4sSensor.new(): PlacedC4sSensor
	return setmetatable({
		rayParams = nil :: RaycastParams?
	}, PlacedC4sSensor)
end

function PlacedC4sSensor.getRequiredMemories(self: PlacedC4sSensor): { MemoryModuleTypes.MemoryModuleType<any> }
	return { MemoryModuleTypes.VISISBLE_C4 }
end

function PlacedC4sSensor.getScanRate(self: PlacedC4sSensor): number
	return 1/20 -- how many times doUpdate is run
end

function PlacedC4sSensor.doUpdate(self: PlacedC4sSensor, agent: Agent, deltaTime: number)
	local visibleC4: { [string]: true } = {}
	
	for entityUID, entity in pairs(EntityManager.Entities) do
		local isInVision = self:isInVision(agent, entity)
		if not isInVision then continue end
		
		visibleC4[entityUID] = true
	end

	local brain = agent:getBrain()
	brain:setNullableMemory(MemoryModuleTypes.VISISBLE_C4, visibleC4)
end

function PlacedC4sSensor.isInVision(self: PlacedC4sSensor, agent: Agent, entity: EntityManager.Entity): boolean
	local agentPrimaryPart = agent:getPrimaryPart()

	local agentPos = agentPrimaryPart.Position
	local entityPos = entity.position
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
	if not rayParams then -- THIS?
		local newRayParams = RaycastParams.new()
		newRayParams.FilterType = Enum.RaycastFilterType.Exclude
		newRayParams.FilterDescendantsInstances = { agent.character }
		self.rayParams = newRayParams
		rayParams = newRayParams
	end

	local rayResult = workspace:Raycast(agentPos, diff.Unit * agent:getSightRadius(), rayParams)
	if not rayResult then
		--Debris:AddItem(Draw.raycast(agentPos, diff.Unit * agent:getSightRadius(), Color3.new(1, 0, 0)), 0.05)
		return false
	end
	
	if entity.instance then
		if rayResult.Instance:IsDescendantOf(entity.instance) or rayResult.Instance == entity.instance then
			return true
		end
	else
		if (rayResult.Position - entityPos).Magnitude < 0.05 then
			return true
		end
	end
	
	return false
end

return PlacedC4sSensor