--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DebugPackets = require(ReplicatedStorage.shared.network.DebugPackets)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local SoundListener = require(ServerScriptService.server.world.sound.SoundListener)
local VoxelWorld = require(ServerScriptService.server.world.level.voxel.VoxelWorld)
local DetectableSound = require(ServerScriptService.server.world.sound.DetectableSound)

local DEBUG_LAST_VISITED_NODE = false
local DEBUG_INDIVIDUAL_COMPUTE_TIME = true
local DEBUG_NODES = false
local MAX_CONCURRENT_THREADS = 8
local MAX_SOUNDS_PER_UPDATE = 5 -- Process fewer sounds but all their listeners

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
	activeThreads: number,
	pendingCount: number
}, SoundDispatcher))

type SoundListener = SoundListener.SoundListener

type PendingSound = {
	position: Vector3,
	soundType: DetectableSound.DetectableSound,
	maxTravelRadius: number,
	timestamp: number
}

local function getSqrDistance(vec1: Vector3, vec2: Vector3): number
	local offset = vec1 - vec2
	return offset.X^2 + offset.Y^2 + offset.Z^2
end

local function isInRadius(vec: Vector3, origin: Vector3, radiusSqr: number): boolean
	return getSqrDistance(vec, origin) <= radiusSqr
end

function SoundDispatcher.new(voxelWorld: VoxelWorld.VoxelWorld): SoundDispatcher
	return setmetatable({
		listeners = {},
		pendingSounds = {},
		voxelWorld = voxelWorld,
		activeThreads = 0,
		pendingCount = 0
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
	profile: DetectableSound.DetectableSound,
	position: Vector3
): ()
	local count = self.pendingCount + 1
	self.pendingCount = count
	self.pendingSounds[count] = {
		position = position,
		soundType = profile,
		maxTravelRadius = profile.suspiciousRange,
		timestamp = os.clock()
	}
end

function SoundDispatcher.update(self: SoundDispatcher, deltaTime: number): ()
	if self.pendingCount == 0 then
		return
	end

	local soundsToProcess = math.min(self.pendingCount, MAX_SOUNDS_PER_UPDATE)
	
	for i = soundsToProcess, 1, -1 do
		-- Only start processing if we aren't already pinned
		if self.activeThreads >= MAX_CONCURRENT_THREADS then break end
		
		local sound = self.pendingSounds[i]
		local radiusSqr = sound.maxTravelRadius^2

		self.pendingSounds[i] = self.pendingSounds[self.pendingCount]
		self.pendingSounds[self.pendingCount] = nil
		self.pendingCount -= 1

		for listener in self.listeners do
			if not listener:canReceiveSound() then continue end
			
			local listenerPos = listener:getPosition()
			if isInRadius(listenerPos, sound.position, radiusSqr) then
				self:dispatchToListener(listener, sound)
			end
		end
	end
end

function SoundDispatcher.dispatchToListener(self: SoundDispatcher, listener: SoundListener, sound: PendingSound)
	if self.activeThreads >= MAX_CONCURRENT_THREADS then 
		return 
	end

	self.activeThreads += 1
	task.spawn(function()
		if listener:checkExtraConditionsBeforeCalc(sound.position, sound.soundType) then
			local startTime = DEBUG_INDIVIDUAL_COMPUTE_TIME and os.clock() or nil
			local cost, lastPos, debugNodes = self.voxelWorld:getSoundPathAsync(
				sound.position,
				listener:getPosition(),
				sound.maxTravelRadius
			)

			if DEBUG_LAST_VISITED_NODE then
				Draw.point(lastPos)
			end

			if DEBUG_INDIVIDUAL_COMPUTE_TIME and startTime then
				print("SoundDispatcher: Individual computation time took:", os.clock() - startTime)
			end

			if cost < sound.maxTravelRadius then
				listener:onReceiveSound(sound.position, cost, lastPos, sound.soundType)

				if DEBUG_NODES then
					DebugPackets.sendDynamicDebugPayloadToClients(DebugPackets.Packets.DEBUG_COMPUTED_VOXELS, debugNodes)
				end
			end
		end
		self.activeThreads -= 1
	end)
end

function SoundDispatcher.setDebugSendDebugPackets(bool: boolean): ()
	DEBUG_NODES = bool
end

return SoundDispatcher