--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local PerceptiveAgent = require(ServerScriptService.server.PerceptiveAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

local VisiblePlayersSensor = {}
VisiblePlayersSensor.__index = VisiblePlayersSensor

export type VisiblePlayersSensor = typeof(setmetatable({} :: {
	rayParams: RaycastParams?,
}, VisiblePlayersSensor))

type Agent = Agent.Agent & PerceptiveAgent.PerceptiveAgent

function VisiblePlayersSensor.new(): VisiblePlayersSensor
	return setmetatable({
		rayParams = nil :: RaycastParams?
	}, VisiblePlayersSensor)
end

function VisiblePlayersSensor.getRequiredMemories(self: VisiblePlayersSensor): { MemoryModuleTypes.MemoryModuleType<any> }
	return { MemoryModuleTypes.VISIBLE_PLAYERS }
end

function VisiblePlayersSensor.getScanRate(self: VisiblePlayersSensor): number
	return 1/20
end

function VisiblePlayersSensor.doUpdate(self: VisiblePlayersSensor, agent: Agent, deltaTime: number)
	local visiblePlayers: { [Player]: true } = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local isInVision = self:isInVision(agent, player)
		if not isInVision then continue end

		visiblePlayers[player] = true
	end

	-- NOTES: I don't know if this matters but, we're setting a new table each update
	-- instead of setting the visible and not visible players. Although that will require
	-- 2 for loops, soo ehh??
	local brain = agent:getBrain()
	brain:setNullableMemory(MemoryModuleTypes.VISIBLE_PLAYERS, visiblePlayers)
end

function VisiblePlayersSensor.isInVision(self: VisiblePlayersSensor, agent: Agent, player: Player): boolean
	local playerCharacter = player.Character
	if not playerCharacter then return false end

	local primaryPart = playerCharacter.PrimaryPart
	if not primaryPart then return false end

	local agentPrimaryPart = agent:getPrimaryPart()

	local agentPos = agentPrimaryPart.Position
	local playerPos = primaryPart.Position
	local diff = playerPos - agentPos
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
		rayParams = newRayParams
	end

	local rayResult = workspace:Raycast(agentPos, diff.Unit * agent:getSightRadius(), rayParams)
	if rayResult and rayResult.Instance:IsDescendantOf(playerCharacter) then
		return true
	end

	return false
end

return VisiblePlayersSensor