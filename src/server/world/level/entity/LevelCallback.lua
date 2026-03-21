--!strict

export type LevelCallback<T> = {
	onTickingStart: (self: LevelCallback<T>, entity: T) -> (),
	onTickingStop: (self: LevelCallback<T>, entity: T) -> ()
}

return nil