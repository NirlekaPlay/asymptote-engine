--!strict

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

function TargetNearbySensor.update(self: TargetNearbySensor, agentPosition: Vector3, players: {Player}): ()
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

		if not ((primaryPart.Position - agentPosition).Magnitude <= self.insideRange) then
			continue
		end

		table.insert(detectedTargets, player)
	end

	self.detectedTargets = detectedTargets
	--print(detectedTargets)
end

return TargetNearbySensor