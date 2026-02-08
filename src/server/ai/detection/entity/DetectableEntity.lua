--!strict

export type DetectableEntity = {
	getUuid: (self: DetectableEntity) -> string,
	getPosition: (self: DetectableEntity) -> Vector3,
	getBasePriority: (self: DetectableEntity) -> number,
	getPriority: (self: DetectableEntity) -> number,
	getDetectionMultiplier: (self: DetectableEntity) -> number,
	getMovementMultiplier: (self: DetectableEntity) -> number
}

return nil