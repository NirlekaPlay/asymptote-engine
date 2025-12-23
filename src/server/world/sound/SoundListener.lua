--!strict

--[=[
	@class SoundListener
	
	Interface for entities that can 'listen' sounds.
	Typically implemented by NPCs or other AI entities.
]=]

export type SoundListener = {
	getPosition: (self: SoundListener) -> Vector3,
	canListen: (self: SoundListener) -> boolean,
	onReceiveSound: (self: SoundListener, soundPosition: Vector3, cost: number, soundType: string) -> (),
	checkExtraConditionsBeforeCalc: (self: SoundListener, origin: Vector3, soundType: string) -> ()
}

return nil