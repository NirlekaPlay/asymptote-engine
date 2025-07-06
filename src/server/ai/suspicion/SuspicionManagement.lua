--!strict

local SUSPICION_STATES = {
	CALM = "CALM",
	SUSPICIOUS = "SUSPICIOUS",
	ALERTED = "ALERTED"
}

local CONFIG = {
	MAX_SUSPICION = 1.0,
	SUSPICIOUS_THRESHOLD = 0.3,   -- Becomes SUSPICIOUS at 30%
	ALERTED_THRESHOLD = 1.0,      -- Becomes ALERTED at 100%
	
	SUSPICION_DECAY_RATE = 0.05,  -- How fast suspicion decreases per update
	SUSPICION_RAISE_RATE = 0.07,  -- Base rate for raising suspicion
}

local SuspicionManagement = {}
SuspicionManagement.__index = SuspicionManagement

export type SuspicionManagement = typeof(setmetatable({} :: {
	suspicionLevels: { [Player]: number },
	currentState: "CALM" | "SUSPICIOUS" | "ALERTED",
	focusedSuspect: Player?
}, SuspicionManagement))

local function getSuspectSuspicionWeight(suspect: Player): number
	return 1.0
end

function SuspicionManagement.new(): SuspicionManagement
	return setmetatable({
		suspicionLevels = {},
		currentState = SUSPICION_STATES.CALM,
		focusedSuspect = nil :: Player?
	}, SuspicionManagement)
end

function SuspicionManagement.increaseSuspicionOnSuspect(self: SuspicionManagement, suspect: Player): ()
	local suspicionWeight = getSuspectSuspicionWeight(suspect)
	local increase = CONFIG.SUSPICION_RAISE_RATE * suspicionWeight
	local currentSuspicion = self.suspicionLevels[suspect] or 0.0
	self.suspicionLevels[suspect] = math.min(CONFIG.MAX_SUSPICION, currentSuspicion + increase)
end

function SuspicionManagement.lowerSuspicionOnSuspect(self: SuspicionManagement, suspect: Player)
	local currentSuspicion = self.suspicionLevels[suspect] or 0.0
	
	if currentSuspicion > 0 then
		self.suspicionLevels[suspect] = math.max(0.0, currentSuspicion - CONFIG.SUSPICION_DECAY_RATE)
	end
end

function SuspicionManagement.update(self: SuspicionManagement): ()
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		--warn(player.Character.Raise.Value)
		if not player.Character then
			continue
		end

		if (player.Character:WaitForChild("Raise") :: BoolValue).Value then
			self:increaseSuspicionOnSuspect(player)
		else
			self:lowerSuspicionOnSuspect(player)
		end
	end

	print(self.suspicionLevels)
end

return SuspicionManagement