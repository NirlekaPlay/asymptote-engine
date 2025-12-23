--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local SoundListener = require(ServerScriptService.server.world.sound.SoundListener)
local VoxelWorld = require(ServerScriptService.server.world.level.voxel.VoxelWorld)

local DEFAULT_MAX_CALCULATIONS_PER_FRAME = 10
local DEFAULT_TARGET_BUDGET_PER_FRAME = 0.003  -- budget per frame in miliseconds
local DEBUG_PRINT_BUDGETS = true

--[=[
	@class SoundDispatcher

	Acts as the central traffic controller for sound propagation and listener management.
	Handles the registration, simulation, and throttled pathfinding calculations.
]=]
local SoundDispatcher = {}
SoundDispatcher.__index = SoundDispatcher

export type SoundDispatcher = typeof(setmetatable({} :: {
	listeners: { [SoundListener.SoundListener]: true },
	pendingSounds: { PendingSound },
	voxelWorld: VoxelWorld.VoxelWorld,
	maxCalculationsPerFrame: number,
	lastFrameCalculationTime: number,
	targetFrameBudget: number
}, SoundDispatcher))

type SoundListener = SoundListener.SoundListener

type PendingSound = {
	position: Vector3,
	soundType: string,
	maxTravelRadius: number,
	timestamp: number
}

type CalculationTicket = {
	sound: PendingSound,
	listener: SoundListener,
	distance: number
}

local function getSqrDistance(vec1: Vector3, vec2: Vector3): number
	local offset = vec1 - vec2
	return offset.X^2 + offset.Y^2 + offset.Z^2
end

local function isInRadius(vec: Vector3, origin: Vector3, radius: number): boolean
	-- Will this make a difference?
	-- Probably not.
	-- But I'm gonna do it anyway.
	return getSqrDistance(vec, origin) <= radius^2
end

function SoundDispatcher.new(voxelWorld: VoxelWorld.VoxelWorld): SoundDispatcher
	return setmetatable({
		listeners = {},
		pendingSounds = {},
		voxelWorld = voxelWorld,
		maxCalculationsPerFrame = DEFAULT_MAX_CALCULATIONS_PER_FRAME,
		lastFrameCalculationTime = 0,
		targetFrameBudget = DEFAULT_TARGET_BUDGET_PER_FRAME
	}, SoundDispatcher)
end

function SoundDispatcher.registerListener(self: SoundDispatcher, listener: SoundListener): ()
	self.listeners[listener] = true
end

function SoundDispatcher.deregisterListener(self: SoundDispatcher, listener: SoundListener): ()
	self.listeners[listener] = nil
end

function SoundDispatcher.emitSound(
	self: SoundDispatcher,
	position: Vector3,
	soundType: string,
	maxTravelRadius: number
): ()
	table.insert(self.pendingSounds, {
		position = position,
		soundType = soundType,
		maxTravelRadius = maxTravelRadius,
		timestamp = os.clock()
	})
end

function SoundDispatcher.update(self: SoundDispatcher, deltaTime: number): ()
	local soundsToProcess = self:getValidPendingSounds()

	if next(soundsToProcess) == nil then
		return
	end

	if DEBUG_PRINT_BUDGETS then
		print(`Target frame budget: {self.targetFrameBudget}`)
		print(`Max calculations per frame: {self.maxCalculationsPerFrame}`)
		print(`Last frame calculation time: {self.lastFrameCalculationTime}`)
	end

	local tickets: { CalculationTicket } = self:getSortedTickets(soundsToProcess)

	-- O(*sodding terrible*)
	-- Process tickets with budget management
	local calculationsThisFrame = 0
	local calculationStartTime = os.clock()

	for _, ticket in tickets do
		-- Check if we've exceeded our frame budget
		-- TODO: The fucking loops in this goddamn function,
		-- someone please find a way to fix this shit
		if calculationsThisFrame >= self.maxCalculationsPerFrame then
			-- Re-add unprocessed sounds back to pending
			local processedSounds = {}
			for i = calculationsThisFrame + 1, #tickets do
				local unprocessedSound = tickets[i].sound
				if not processedSounds[unprocessedSound] then
					table.insert(self.pendingSounds, unprocessedSound)
					processedSounds[unprocessedSound] = true
				end
			end
			break
		end

		if not ticket.listener:checkExtraConditionsBeforeCalc(ticket.sound.position, ticket.sound.soundType) then
			continue
		end
		
		-- TODO: This function yields. And since this update function is invoked
		-- from the RunService.PreSimulation, it may lead to conflicts.
		local cost = self.voxelWorld:getSoundPathAsync(
			ticket.listener:getPosition(),
			ticket.sound.position,
			ticket.sound.maxTravelRadius
		)

		if cost < ticket.sound.maxTravelRadius then
			-- It can be heard, notify the listener
			ticket.listener:onReceiveSound(
				ticket.sound.position,
				cost,
				ticket.sound.soundType
			)
		end
		
		calculationsThisFrame += 1
	end

	-- Adjust max calculations for next frame based on time spent
	local totalCalculationTime = os.clock() - calculationStartTime
	self.lastFrameCalculationTime = totalCalculationTime

	-- Dynamic budget adjustment
	if totalCalculationTime > self.targetFrameBudget and self.maxCalculationsPerFrame > 1 then
		self.maxCalculationsPerFrame = math.max(1, self.maxCalculationsPerFrame - 1)
	elseif totalCalculationTime < self.targetFrameBudget * 0.5 and calculationsThisFrame >= self.maxCalculationsPerFrame then
		self.maxCalculationsPerFrame = math.min(20, self.maxCalculationsPerFrame + 1)
	end
end

function SoundDispatcher.getValidPendingSounds(self: SoundDispatcher): { PendingSound }
	-- Remove sounds with no listeners in range
	local soundsToProcess: { PendingSound } = {}
	local processCount = 0
	local pending = self.pendingSounds

	for i = 1, #pending do
		local sound = pending[i]
		local hasListenersInRange = false

		for listener in self.listeners do
			if listener:canListen() then
				if isInRadius(listener:getPosition(), sound.position, sound.maxTravelRadius) then
					hasListenersInRange = true
					break
				end
			end
		end
		
		if hasListenersInRange then
			processCount = processCount + 1
			soundsToProcess[processCount] = sound
		end
	end

	-- I don't know if setting it to {} or uisng table.clear is better
	-- cuz setting it to {} will make a new table which may lead to some
	-- memory reference issues but ehhhhhhh
	self.pendingSounds = {}

	return soundsToProcess
end

function SoundDispatcher.getSortedTickets(self: SoundDispatcher, soundsToProcess: { PendingSound }): { CalculationTicket }
	local tickets: { CalculationTicket } = {}
	
	for _, sound in soundsToProcess do
		for listener in self.listeners do
			if listener:canListen() then
				local distance = getSqrDistance(listener:getPosition(), sound.position)

				if distance <= sound.maxTravelRadius^2 then
					table.insert(tickets, {
						sound = sound,
						listener = listener,
						distance = distance
					})
				end
			end
		end
	end

	-- Sort tickets: closest listeners get priority
	-- And I swear to God the typechecking on this
	table.sort(tickets, function(a: CalculationTicket, b: CalculationTicket)
		return a.distance < b.distance
	end)

	return tickets
end

return SoundDispatcher