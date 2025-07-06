--!strict

local CONFIG = {
	MAX_SUSPICION = 1.0,
	SUSPICION_DECAY_RATE = 0.5,  -- How fast suspicion decreases per update
	SUSPICION_RAISE_RATE = 0.7,  -- Base rate for raising suspicion
}

--[=[
	@class SuspicionManagement

	Manages the raising and lowering of suspicion per player.
]=]
local SuspicionManagement = {}
SuspicionManagement.__index = SuspicionManagement

export type SuspicionManagement = typeof(setmetatable({} :: {
	suspicionLevels: { [Player]: number }
}, SuspicionManagement))

local function getSuspectSuspicionWeight(suspect: Player): number
	return 1.0
end

function SuspicionManagement.new(): SuspicionManagement
	return setmetatable({
		suspicionLevels = {}
	}, SuspicionManagement)
end

function SuspicionManagement.increaseSuspicion(self: SuspicionManagement, suspect: Player, deltaTime: number): ()
	local suspicionWeight = getSuspectSuspicionWeight(suspect)
	local increase = CONFIG.SUSPICION_RAISE_RATE * suspicionWeight * deltaTime
	local currentSuspicion = self.suspicionLevels[suspect] or 0.0
	self.suspicionLevels[suspect] = math.min(CONFIG.MAX_SUSPICION, currentSuspicion + increase)
end

function SuspicionManagement.decreaseSuspicion(self: SuspicionManagement, suspect: Player, deltaTime: number): ()
	local currentSuspicion = self.suspicionLevels[suspect] or 0.0

	if currentSuspicion > 0 then
		local decrease = CONFIG.SUSPICION_DECAY_RATE * deltaTime
		self.suspicionLevels[suspect] = math.max(0.0, currentSuspicion - decrease)

		-- clean up once the level reaches zero
		if self.suspicionLevels[suspect] <= 0 then
			self.suspicionLevels[suspect] = nil
		end
	end
end

function SuspicionManagement.update(self: SuspicionManagement, deltaTime: number, visiblePlayers: { Player }): ()
	-- increase suspicion for visible players
	for _, player in visiblePlayers do
		self:increaseSuspicion(player, deltaTime)
	end

	-- decrease suspicion for non-visible players
	for suspect, _ in pairs(self.suspicionLevels) do
		if not table.find(visiblePlayers, suspect) then
			self:decreaseSuspicion(suspect, deltaTime)
		end
	end

	print(self.suspicionLevels)
end

return SuspicionManagement