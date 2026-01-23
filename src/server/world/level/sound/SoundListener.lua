--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local DetectableSound = require(ServerScriptService.server.world.level.sound.DetectableSound)

--[=[
	@class SoundListener
	
	Interface for entities that can 'listen' sounds.
	Typically implemented by NPCs or other AI entities.
]=]

export type SoundListener = {
	getPosition: (self: SoundListener) -> Vector3,
	canReceiveSound: (self: SoundListener) -> boolean,
	onReceiveSound: (self: SoundListener, soundPos: Vector3, cost: number, lastPos: Vector3, sound: DetectableSound.DetectableSound) -> (),
	checkExtraConditionsBeforeCalc: (self: SoundListener, origin: Vector3, sound: DetectableSound.DetectableSound) -> boolean
}

return nil