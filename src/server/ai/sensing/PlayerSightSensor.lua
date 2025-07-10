--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ExpireableValue = require(ServerScriptService.server.ai.memory.ExpireableValue)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

--[=[
	@class PlayerSightSensor
]=]
local PlayerSightSensor = {}
PlayerSightSensor.__index = PlayerSightSensor

export type PlayerSightSensor = typeof(setmetatable({} :: {
	agent: any,
	sightRadius: number,
	sightPeriphAngle: number
}, PlayerSightSensor))

function PlayerSightSensor.new(agent, sightRadius: number, sightPeriphAngle: number): PlayerSightSensor
	return setmetatable({
		agent = agent,
		sightRadius = sightRadius,
		sightPeriphAngle = sightPeriphAngle
	}, PlayerSightSensor)
end

function PlayerSightSensor.update(self: PlayerSightSensor, agentPosition: Vector3): ()
	local players = Players:GetPlayers()

	-- breaks SRP and a shitton of other programming principles.
	-- but hey. if it works, IT WORKS.

	-- this is too long. standards say lines shouldnt be more than 100 characters long. too bad!
	local agentVisiblePlayersMemory = (self.agent.memories[MemoryModuleTypes.VISIBLE_PLAYERS] :: ExpireableValue.ExpireableValue<{ [Player]: true }>).value

	for _, player in ipairs(players) do
		local isInVision = self:isInVision(player)
		if not isInVision then
			agentVisiblePlayersMemory[player] = nil
			continue
		end

		agentVisiblePlayersMemory[player] = true
	end
end

function PlayerSightSensor.isInVision(self: PlayerSightSensor, player: Player): boolean
	local playerCharacter = player.Character
	if not playerCharacter then return false end

	local primaryPart = playerCharacter.PrimaryPart
	if not primaryPart then return false end

	local agentPrimaryPart = self.agent:getPrimaryPart()

	local diff = primaryPart.Position - agentPrimaryPart.Position
	local dist = diff.Magnitude

	if dist > self.sightRadius then
		return false
	end

	local dot = agentPrimaryPart.CFrame.LookVector:Dot(diff.Unit)

	local cosHalfAngle = math.cos(math.rad(self.sightPeriphAngle / 2))
	if dot < cosHalfAngle then
		return false
	end

	if not self:rayStrategy(playerCharacter, primaryPart) then
		return false
	end

	return true
end

function PlayerSightSensor.rayStrategy(
	self: PlayerSightSensor,
	playerCharacter: Model,
	targetPart: BasePart
): boolean

	local agentPrimaryPart: BasePart = self.agent:getPrimaryPart()
	local rayDirection = (targetPart.Position - agentPrimaryPart.Position).Unit * self.sightRadius
	local rayResult = workspace:Raycast(agentPrimaryPart.Position, rayDirection)
	if not rayResult then return false end

	if rayResult.Instance:IsDescendantOf(playerCharacter) then
		return true
	end

	return false
end

return PlayerSightSensor