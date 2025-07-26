--!strict

local Behavior = require(script.Parent.Behavior)

export type BehaviorControl<T> = {
	getStatus: (self: BehaviorControl<T>) -> Behavior.Status,
	tryStart: (self: BehaviorControl<T>, agent: T) -> boolean,
	updateOrStop: (self: BehaviorControl<T>, agent: T) -> (),
	doStop: (self: BehaviorControl<T>, agent: T) -> ()
}

return nil