--!strict

--[=[
	@class SoundListener
	
	Interface for entities that can 'listen' sounds.
	Typically implemented by NPCs or other AI entities.
]=]

export type SoundListener = {
	getPosition: (self: SoundListener) -> Vector3,
	canReceiveSound: (self: SoundListener) -> boolean,
	onReceiveSound: (self: SoundListener, soundPos: Vector3, cost: number, lastPos: Vector3, soundType: string) -> (),
	checkExtraConditionsBeforeCalc: (self: SoundListener, origin: Vector3, soundType: string) -> boolean
}

return nil