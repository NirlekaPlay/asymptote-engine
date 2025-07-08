--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStatusReg = require(ServerScriptService.server.player.PlayerStatusReg)

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
		local statuses = PlayerStatusReg.getStatus(player)
		if not statuses then
			continue
		end
		if next(statuses) == nil then
			continue
		end
		local character = player.Character
		if not character then
			continue
		end
		local primaryPart = character.PrimaryPart
		if not primaryPart then
			continue
		end
		local susWeight = PlayerStatusReg.getStatus(player)
		if not susWeight then
			return
		end

		if next(susWeight) == nil then
			return
		end

		if not ((primaryPart.Position - agentPosition).Magnitude <= self.insideRange) then
			continue
		end

		local raycastResult = workspace:Raycast(agentPosition, (primaryPart.Position - agentPosition).Unit * self.insideRange)
		if not raycastResult then
			return
		end

		if raycastResult.Instance:IsDescendantOf(character) then
			table.insert(detectedTargets, player)
		end
	end

	self.detectedTargets = detectedTargets
	--print(detectedTargets)
end

return TargetNearbySensor