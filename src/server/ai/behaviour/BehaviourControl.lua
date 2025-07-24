--!strict

local Behaviour = require(script.Parent.Behaviour)

export type BehaviourControl<T> = {
	getStatus: (self: BehaviourControl<T>) -> Behaviour.Status,
	tryStart: (self: BehaviourControl<T>, agent: T) -> boolean,
	updateOrStop: (self: BehaviourControl<T>, agent: T) -> (),
	doStop: (self: BehaviourControl<T>, agent: T) -> ()
}

return nil