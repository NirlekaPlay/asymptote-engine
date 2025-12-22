--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local SoundListener = require(ServerScriptService.server.world.sound.SoundListener)

--[=[
	@class SoundDispatcher
]=]
local SoundDispatcher = {}
SoundDispatcher.__index = SoundDispatcher

export type SoundDispatcher = typeof(setmetatable({} :: {
	listeners: { [ SoundListener ]: true }
}, SoundDispatcher))

type SoundListener = SoundListener.SoundListener

function SoundDispatcher.new(): SoundDispatcher
	return setmetatable({
		listeners = {}
	}, SoundDispatcher)
end

function SoundDispatcher.registerListener(self: SoundDispatcher, listener: SoundListener): ()
	self.listeners[listener] = true
end

function SoundDispatcher.deregisterListener(self: SoundDispatcher, listener: SoundListener): ()
	self.listeners[listener] = nil
end

function SoundDispatcher.emitSound(self: SoundDispatcher): ()
	
end

function SoundDispatcher.update(self: SoundDispatcher, deltaTime: number): ()
	
end

return SoundDispatcher