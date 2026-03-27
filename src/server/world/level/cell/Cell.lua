--!strict

local Cell = {}

Cell.BoundType = {
	FLOOR = 0 :: BoundType,
	ROOF = 1 :: BoundType
}

export type Cell = {
	name: string,
	hasFloor: boolean,
	locationStr: string?,
	bounds: { Bounds }
}

export type Bounds = {
	cframe: CFrame,
	size: Vector3,
	type: BoundType
}

type BoundType = number

return Cell