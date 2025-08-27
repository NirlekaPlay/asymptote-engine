--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStatus = require(ServerScriptService.server.player.PlayerStatus)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local CellConfig = require(script.Parent.CellConfig)

-- what in the actual heavenly fuck?
local cellsPerCellName: { [string]: Cell } = {}
local boundsPerCells: { [Cell]: {Bounds} } = {}
local configsPerCells: { [Cell]: CellConfig.Config } = {}
local playersRootPart: { [BasePart]: Player } = {}
local playerCell: { [Player]: Cell } = {} -- Cache: player -> current cell
local cellPlayers: { [Cell]: { [Player]: true } } = {} -- Cache: cell -> players,
local playerBounds: { [Player]: Bounds } = {}
local playerZonePenalties: { [Player]: { [PlayerStatus.PlayerStatusType]: true } } = {}
local currentOverlapParams = OverlapParams.new()
currentOverlapParams.FilterType = Enum.RaycastFilterType.Include

--[=[
	@class Cell

	Cell represents a logical zone in a level, which may consist of one or more 
	discrete regions (Bounds). Multiple models with the same name are unified into 
	a single Cell, allowing for consistent configuration and behavior across 
	non-contiguous areas.

	## Structure

	```
	Cell
	└── CellName       -- Unique identifier for the Cell
	└── Bounds         -- One or more regions that belong to this Cell
		├── CFrame     --
		├── Size       --
		└── AreaName   -- Optional sub-identifier for dialogue
	```

	## Example Hierarchy in Workspace

	```
	Workspace/
	└── Level/
		└── Cells/
			├── BobZone
			├── BobZone
			├── BobZone
			├── JeiaZone
			└── JoeZone
	```

	In this example, three BobZone models are unified into a single `BobZone` Cell.
	Each model contributes a Bound with its own CFrame, Size, and optional AreaName.

	```
	BobZone
	└── CellName: "BobZone"
	└── Bounds
		├── Bound #1
		│   ├── CFrame
		│   ├── Size
		│   └── AreaName
		├── Bound #2
		│   ├── CFrame
		│   ├── Size
		│   └── AreaName
		└── Bound #3
			├── CFrame
			├── Size
			└── AreaName
	```

	## Configuration Example

	Cells can be configured in code to define behavior, such as whether
	the cell can apply trespassing status once a Player is in it, and what
	different status may apply:

	```lua
	BobZone = {
		canBeTrespassed = true,
		penalties = {
			disguised = PlayerStatus.Status.MINOR_TRESPASSING,
			undisguised = PlayerStatus.Status.MAJOR_TRESPASSING
		}
	}
	```

	This configuration will apply to all Bounds within the `BobZone` Cell.
	The optional `AreaName` property allows for NPC Guards to specify what name
	of the area the Player is in. For example, if a Player is in BobZone, and they
	are in a bound with the AreaName of 'north office' and is spotted by a Guard,
	the Guard will say "Trespasser in the north office."
]=]
local Cell = {}

export type Bounds = {
	CFrame: CFrame,
	Size: Vector3,
	AreaName: string?
}

export type Cell = {
	CellName: string,
	BoundsList: { Bounds }
}

function Cell.addCell(cellName: string, cellBounds: Bounds, config: CellConfig.Config?): ()
	if not cellsPerCellName[cellName] then
		cellsPerCellName[cellName] = {
			CellName = cellName,
			BoundsList = {}
		}
	end

	-- this is utterly fucking retarded.
	table.insert(cellsPerCellName[cellName].BoundsList, cellBounds)

	if not boundsPerCells[cellsPerCellName[cellName]] then
		boundsPerCells[cellsPerCellName[cellName]] = {}
	end
	table.insert(boundsPerCells[cellsPerCellName[cellName]], cellBounds)

	if config then
		configsPerCells[cellsPerCellName[cellName]] = config
	end
end

function Cell.getCellConfig(cell: Cell): CellConfig.Config?
	return configsPerCells[cell]
end

function Cell.getPlayerOccupiedCell(player: Player): string
	return playerCell[player].CellName
end

function Cell.getPlayerOccupiedAreaName(player: Player): string?
	return playerBounds[player] and playerBounds[player].AreaName or nil
end

--

function Cell.update(): ()
	Cell.updateOverlapParams()
	Cell.recalculatePlayers()
	Cell.updatePlayersTrespassingStatus()
end

function Cell.updateOverlapParams(): ()
	table.clear(playersRootPart)
	local validParts = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if not Cell.isPlayerValid(player) then
			playerCell[player] = nil
			continue
		end

		-- we already checked if it has a root part in isPlayerValid()
		local rootPart = (player.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
		playersRootPart[rootPart] = player
		table.insert(validParts, rootPart)
	end

	currentOverlapParams.FilterDescendantsInstances = validParts
end

function Cell.recalculatePlayers(): ()
	table.clear(cellPlayers)
	table.clear(playerBounds)

	local playersInsideAnyCell: { [Player]: true } = {}
	local assignedPlayers: { [Player]: true } = {} -- track players already assigned

	-- O(*sodding terrible*)
	for cellName, boundsList in pairs(boundsPerCells) do
		local playersInCell: { [Player]: true } = {}

		for _, bounds in ipairs(boundsList) do
			local partsInBounds = workspace:GetPartBoundsInBox(
				bounds.CFrame, bounds.Size, currentOverlapParams
			)

			for _, part in ipairs(partsInBounds) do
				local player = playersRootPart[part]
				if player and not assignedPlayers[player] and Cell.isPointWithinBounds(part.Position, bounds) then
					playersInCell[player] = true
					playerCell[player] = cellName
					playersInsideAnyCell[player] = true
					assignedPlayers[player] = true
					playerBounds[player] = bounds
				end
			end
		end

		cellPlayers[cellName] = playersInCell
	end

	-- remove players from playerCell if they're not in any cell anymore
	for player in pairs(playerCell) do
		if not playersInsideAnyCell[player] then
			playerCell[player] = nil
		end
	end
end

function Cell.updatePlayersTrespassingStatus(): ()
	for player, cell in pairs(playerCell) do
		local cellConfig = Cell.getCellConfig(cell)
		if not cellConfig or not cellConfig.canBeTrespassed then
			continue
		end

		local playerStatus = PlayerStatusRegistry.getPlayerStatuses(player)
		if not playerStatus then
			continue
		end

		local disguised = playerStatus:hasStatus("DISGUISED")
		local penalty: PlayerStatus.PlayerStatusType?

		if disguised then
			penalty = cellConfig.penalties.disguised
		else
			penalty = cellConfig.penalties.undisguised
		end

		local appliedPenalties: { [PlayerStatus.PlayerStatusType]: true } = playerZonePenalties[player] or {}

		-- apply current penalty if applicable
		if penalty and not playerStatus:hasStatus(penalty) then
			playerStatus:addStatus(penalty)
		end

		-- remove penalties that are no longer relevant
		for appliedPenalty in pairs(appliedPenalties) do
			if appliedPenalty ~= penalty then
				playerStatus:removeStatus(appliedPenalty)
				appliedPenalties[appliedPenalty] = nil
			end
		end

		if penalty then
			appliedPenalties[penalty] = true
		end

		playerZonePenalties[player] = appliedPenalties
	end

	-- also handle players who left all trespassable zones
	for player, appliedPenalties in pairs(playerZonePenalties) do
		if not playerCell[player] then
			local playerStatus = PlayerStatusRegistry.getPlayerStatuses(player)
			for appliedPenalty in pairs(appliedPenalties) do
				playerStatus:removeStatus(appliedPenalty)
			end
			playerZonePenalties[player] = nil
		end
	end
end

--

function Cell.isPlayerValid(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end

	if not character:FindFirstChild("HumanoidRootPart") then
		return false 
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return (humanoid and humanoid.Health > 0) :: boolean
end

function Cell.isPointWithinBounds(point: Vector3, bounds: Bounds): boolean
	local v3 = bounds.CFrame:PointToObjectSpace(point)
	return math.abs(v3.X) <= bounds.Size.X / 2
		and math.abs(v3.Y) <= bounds.Size.Y / 2
		and math.abs(v3.Z) <= bounds.Size.Z / 2
end

return Cell