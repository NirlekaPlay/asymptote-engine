--!strict

export type Fields = {
	id: number,
	updatesPerSec: number?,
	_elapsed: number,
}

export type Prop = Fields & {
	getId: (self: Prop) -> number,
	destroy: ((self: Prop) -> ())?,
	restart: ((self: Prop) -> ())?,
	update: ((self: Prop, deltaTime: number) -> ())?
}

return nil