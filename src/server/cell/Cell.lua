--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStatus = require(ServerScriptService.server.player.PlayerStatus)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local CellConfig = require(script.Parent.CellConfig)

local boundsPerCells: { [string]: {Bounds} } = {}
local configsPerCells: { [string]: CellConfig.Config } = {}
local playersRootPart: { [BasePart]: Player } = {}
local playerCell: { [Player]: string } = {} -- Cache: player -> current cell
local playerZonePenalties: { [Player]: { [PlayerStatus.PlayerStatusType]: true } } = {}
local cellPlayers: { [string]: { [Player]: true } } = {} -- Cache: cell -> players
local currentOverlapParams = OverlapParams.new()
currentOverlapParams.FilterType = Enum.RaycastFilterType.Include

--[=[
	@class Cell
]=]
local Cell = {}

export type Bounds = {
	CFrame: CFrame,
	Size: Vector3
}

function Cell.addCell(cellName: string, cellBounds: Bounds, config: CellConfig.Config?): ()
	if not boundsPerCells[cellName] then
		boundsPerCells[cellName] = {}
	end

	table.insert(boundsPerCells[cellName], cellBounds)

	if config then
		configsPerCells[cellName] = config
	end
end

function Cell.getCellConfig(cellName: string): CellConfig.Config?
	return configsPerCells[cellName]
end

function Cell.getPlayerOccupiedCell(player: Player): string
	return playerCell[player]
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

	local playersInsideAnyCell: { [Player]: true } = {}

	-- O(*sodding terrible*)
	for cellName, boundsList in pairs(boundsPerCells) do
		local playersInCell:{ [Player]: true } = {}

		for _, bounds in ipairs(boundsList) do
			local partsInBounds = workspace:GetPartBoundsInBox(
				bounds.CFrame, bounds.Size, currentOverlapParams
			)

			for _, part in ipairs(partsInBounds) do
				local player = playersRootPart[part]
				if player and Cell.isPointWithinBounds(part.Position, bounds) then
					playersInCell[player] = true
					playerCell[player] = cellName
					playersInsideAnyCell[player] = true
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
	for player, cellName in pairs(playerCell) do
		local cellConfig = Cell.getCellConfig(cellName)
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