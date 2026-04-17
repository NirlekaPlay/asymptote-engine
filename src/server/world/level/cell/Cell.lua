--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local CellConfig = require(ServerScriptService.server.world.level.cell.CellConfig)

local Cell = {}

Cell.BoundType = {
	FLOOR = 0 :: BoundType,
	ROOF = 1 :: BoundType
}

export type Cell = {
	name: string,
	hasFloor: boolean,
	locationStr: string?,
	bounds: { Bounds },
	config: CellConfig.CellConfig?
}

export type Bounds = {
	cframe: CFrame,
	size: Vector3,
	type: BoundType
}

type BoundType = number

return Cell