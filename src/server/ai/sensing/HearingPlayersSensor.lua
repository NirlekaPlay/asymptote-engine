--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)
local PerceptiveAgent = require(ServerScriptService.server.PerceptiveAgent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

local MIN_WALK_SPEED = 16

local HearingPlayersSensor = {}
HearingPlayersSensor.__index = HearingPlayersSensor

export type HearingPlayersSensor = typeof(setmetatable({} :: {
	rayParams: RaycastParams?,
}, HearingPlayersSensor))

type Agent = Agent.Agent & PerceptiveAgent.PerceptiveAgent

function HearingPlayersSensor.new(): HearingPlayersSensor
	return setmetatable({
		rayParams = nil :: RaycastParams?
	}, HearingPlayersSensor)
end

function HearingPlayersSensor.getRequiredMemories(self: HearingPlayersSensor): { MemoryModuleTypes.MemoryModuleType<any> }
	return { MemoryModuleTypes.HEARABLE_PLAYERS }
end

function HearingPlayersSensor.getScanRate(self: HearingPlayersSensor): number
	return 0.30
end

function HearingPlayersSensor.doUpdate(self: HearingPlayersSensor, agent: Agent, deltaTime: number)
	local visiblePlayers: { [Player]: true } = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if agent:getBrain():getMemory(MemoryModuleTypes.VISIBLE_PLAYERS):isPresent() then
			continue
		end
		local isHeard = self:isHeard(agent, player)
		if not isHeard then continue end

		visiblePlayers[player] = true
	end

	local brain = agent:getBrain()
	brain:setNullableMemory(MemoryModuleTypes.HEARABLE_PLAYERS, visiblePlayers)
end

function HearingPlayersSensor.isHeard(self: HearingPlayersSensor, agent: Agent, player: Player): boolean
	local playerCharacter = player.Character
	if not playerCharacter then return false end

	local primaryPart = playerCharacter.PrimaryPart
	if not primaryPart then return false end

	local agentPrimaryPart = agent:getPrimaryPart()

	local agentPos = agentPrimaryPart.Position
	local playerPos = primaryPart.Position
	local diff = playerPos - agentPos
	local dist = diff.Magnitude

	if dist > agent:getHearingRadius() then
		return false
	end

	local humanoid = playerCharacter:FindFirstChildOfClass("Humanoid") :: Humanoid
	if humanoid.Health <= 0 then
		return false
	end

	if humanoid.MoveDirection.Magnitude <= 0 then
		return false
	end

	if humanoid.WalkSpeed < MIN_WALK_SPEED then
		return false
	end

	local rayParams = self.rayParams
	if not rayParams then
		local newRayParams = RaycastParams.new()
		newRayParams.FilterType = Enum.RaycastFilterType.Exclude
		newRayParams.FilterDescendantsInstances = { agent.character }
		rayParams = newRayParams
		self.rayParams = newRayParams
		rayParams = newRayParams
	end

	local rayResult = workspace:Raycast(agentPos, diff.Unit * agent:getHearingRadius(), rayParams)
	if rayResult and rayResult.Instance:IsDescendantOf(playerCharacter) then
		return true
	end

	return false
end

return HearingPlayersSensor