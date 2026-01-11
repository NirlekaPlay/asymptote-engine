--!strict

export type PositionTracker = {
	getCurrentPosition: (self: PositionTracker) -> Vector3,
}

return nil