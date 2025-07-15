--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TypedDetectionRemote = require(ReplicatedStorage.shared.network.TypedDetectionRemote)
local PlayerStatusReg = require(ServerScriptService.server.player.PlayerStatusReg)

local CONFIG = {
	BASE_DETECTION_TIME = 2.5,
	DECAY_RATE_PER_SECOND = 0.2222 -- Equivalent to 1% per 0.045s
}

--[=[
	@class SuspicionManagement
	Manages the raising and lowering of suspicion per player.
]=]
local SuspicionManagement = {}
SuspicionManagement.__index = SuspicionManagement

export type SuspicionManagement = typeof(setmetatable({} :: {
	model: Model,
	suspicionLevels: { [Player]: number },
	focusingOn: Player?
}, SuspicionManagement))

export type DetectableEntity = {

}

function SuspicionManagement.new(model: Model): SuspicionManagement
	return setmetatable({
		model = model,
		suspicionLevels = {},
		focusingOn = nil :: Player?
	}, SuspicionManagement)
end

function SuspicionManagement.update(
	self: SuspicionManagement,
	deltaTime: number,
	visiblePlayers: { [Player]: true }
): ()

	for player in pairs(visiblePlayers) do
		local playerSusLevel = PlayerStatusReg.getSuspiciousLevel(player)
		if not playerSusLevel:isSuspicious() then
			continue
		end

		local playerSus = self.suspicionLevels[player] or 0
		if playerSus >= 1 then
			continue
		end
		local weight = playerSusLevel:getWeight() or 0
		local speedMultiplier = 1 + (weight / 100)
		local increaseTime = CONFIG.BASE_DETECTION_TIME / speedMultiplier

		playerSus = math.clamp(playerSus + increaseTime * deltaTime, 0.0, 1.0)
		self.suspicionLevels[player] = playerSus

		TypedDetectionRemote:FireClient(player, playerSus, self.model, self.model.PrimaryPart.Position)
	end

	for player, level in pairs(self.suspicionLevels) do
		if not visiblePlayers[player] then
			local finalSus = math.max(0, level - CONFIG.DECAY_RATE_PER_SECOND * deltaTime)
			if finalSus > 0 then
				self.suspicionLevels[player] = finalSus
				TypedDetectionRemote:FireClient(player, finalSus, self.model, self.model.PrimaryPart.Position)
			else
				self.suspicionLevels[player] = nil
			end
		end
	end
end

return SuspicionManagement