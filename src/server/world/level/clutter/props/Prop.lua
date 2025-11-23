--!strict

export type Prop = {
	createFromPlaceholder: (placeholder: BasePart, model: Model?) -> Prop,
	onLevelRestart: (self: Prop) -> (),
	update: (self: Prop, deltaTime: number) -> ()
}

return nil