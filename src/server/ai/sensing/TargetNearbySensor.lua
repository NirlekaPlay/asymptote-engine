--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

--[=[
	@class TargetNearbySensor
]=]
local TargetNearbySensor = {}
TargetNearbySensor.__index = TargetNearbySensor

export type TargetNearbySensor = typeof(setmetatable({} :: {
	insideRange: number,
	detectedTargets: { Player }
}, TargetNearbySensor))

function TargetNearbySensor.new(insideRange: number): TargetNearbySensor
	return setmetatable({
		insideRange = insideRange,
		detectedTargets = {}
	}, TargetNearbySensor)
end

function TargetNearbySensor.update(self: TargetNearbySensor, agentPosition: Vector3): ()
	local players = Players:GetPlayers()
	local detectedTargets = {}
	for _, player in ipairs(players) do
		local character = player.Character
		if not character then
			continue
		end
		local primaryPart = character.PrimaryPart
		if not primaryPart then
			continue
		end
		local susLevel = PlayerStatusRegistry.getPlayerStatuses(player)
		if not susLevel then
			continue
		end
		if not susLevel:hasAnyStatus() then
			continue
		end

		if not ((primaryPart.Position - agentPosition).Magnitude <= self.insideRange) then
			continue
		end

		local raycastResult = workspace:Raycast(agentPosition, (primaryPart.Position - agentPosition).Unit * self.insideRange)
		if not raycastResult then
			continue
		end

		if raycastResult.Instance:IsDescendantOf(character) then
			table.insert(detectedTargets, player)
		end
	end

	self.detectedTargets = detectedTargets
end

return TargetNearbySensor