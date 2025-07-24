--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Agent = require(ServerScriptService.server.Agent)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

local VisiblePlayersSensor = {}
VisiblePlayersSensor.__index = VisiblePlayersSensor

export type VisiblePlayersSensor = typeof(setmetatable({} :: {
	sightRadius: number,
	sightPeriphAngle: number,
	rayParams: RaycastParams?,
	_timeAccumulator: number,
}, VisiblePlayersSensor))

type Agent = Agent.Agent

function VisiblePlayersSensor.new(): VisiblePlayersSensor
	return setmetatable({
		sightRadius = 50,
		sightPeriphAngle = 180,
		rayParams = nil :: RaycastParams?,
		_timeAccumulator = 0
	}, VisiblePlayersSensor)
end

function VisiblePlayersSensor.requires(self: VisiblePlayersSensor): { MemoryModuleTypes.MemoryModuleType<any> }
	return { MemoryModuleTypes.VISIBLE_PLAYERS }
end

function VisiblePlayersSensor.update(self: VisiblePlayersSensor, agent: Agent, deltaTime: number): ()
	self._timeAccumulator += deltaTime

	if self._timeAccumulator >= 1 then
		self._timeAccumulator = 0
		self:doUpdate(agent, deltaTime)
	end
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

	if dist > self.sightRadius then
		return false
	end

	local dot = agentPrimaryPart.CFrame.LookVector:Dot(diff.Unit)

	local cosHalfAngle = math.cos(math.rad(self.sightPeriphAngle / 2))
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

	local rayResult = workspace:Raycast(agentPos, diff.Unit * self.sightRadius, rayParams)
	if rayResult and rayResult.Instance:IsDescendantOf(playerCharacter) then
		return true
	end

	return false
end

return VisiblePlayersSensor