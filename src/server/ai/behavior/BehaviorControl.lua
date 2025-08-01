--!strict

export type Status = "RUNNING"
	| "STOPPED"

export type BehaviorControl<T> = {
	name: string,
	getStatus: (self: BehaviorControl<T>) -> Status,
	tryStart: (self: BehaviorControl<T>, agent: T, currentTime: number) -> boolean,
	updateOrStop: (self: BehaviorControl<T>, agent: T, currentTime: number, deltaTime: number) -> (),
	stop: (self: BehaviorControl<T>, agent: T) -> ()
}

return {
	Status = {
		RUNNING = "RUNNING" :: "RUNNING",
		STOPPED = "STOPPED" :: "STOPPED"
	}
}