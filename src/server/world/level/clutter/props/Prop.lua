--!strict

export type Prop = {
	createFromPlaceholder: (placeholder: BasePart) -> Prop,
	onLevelRestart: (self: Prop) -> ()
}

return nil