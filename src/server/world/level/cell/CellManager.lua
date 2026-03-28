--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local Cell = require(ServerScriptService.server.world.level.cell.Cell)
local CellConfig = require(ServerScriptService.server.world.level.cell.CellConfig)
local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)

--[=[
	@class CellManager
]=]
local CellManager = {}
CellManager.__index = CellManager

export type CellManager = typeof(setmetatable({} :: {
	cells: { Cell },
	cellConfigs: CellConfig.ParsedCellConfigs,
	cellsPerPlayer: { [Player]: Cell },
	playersRootPart: { [BasePart]: Player },
	playerZonePenalties: { [Player]: { [PlayerStatus.PlayerStatus]: true } },
	currentOverlapParams: OverlapParams
}, CellManager))

type Cell = Cell.Cell
type Bounds = Cell.Bounds

local function isPosInCell(pos: Vector3, cell: Cell): boolean
	-- From [InfiltrationEngine's](https://github.com/MoonstoneSkies/InfiltrationEngine-Custom-Missions)
	-- [ZoneUtil](https://github.com/MoonstoneSkies/InfiltrationEngine-Custom-Missions/blob/main/Plugins/src/SerializationTools/Util/ZoneUtil.lua)
	-- module.
	local floorMatch = not cell.hasFloor
	local roofMatch = false

	for _, bound in cell.bounds do
		local rel = bound.cframe:PointToObjectSpace(pos)

		if math.abs(rel.X) <= bound.size.X / 2 and math.abs(rel.Z) <= bound.size.Z / 2 then
			if bound.type == Cell.BoundType.ROOF and rel.Y <= 0 then
				roofMatch = true
			elseif bound.type == Cell.BoundType.FLOOR and rel.Y >= 0 then
				floorMatch = true
			end

			if floorMatch and roofMatch then
				return true
			end
		end
	end
	
	return false
end

function CellManager.new(cells: { Cell }, cellConfigs: CellConfig.ParsedCellConfigs): CellManager
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	return setmetatable({
		cells = cells,
		cellConfigs = cellConfigs,
		cellsPerPlayer = {},
		playersRootPart = {},
		playerZonePenalties = {},
		currentOverlapParams = overlapParams
	}, CellManager)
end

function CellManager.getPlayerCell(self: CellManager, player: Player): Cell?
	return self.cellsPerPlayer[player]
end

function CellManager.getPlayerOccupiedAreaName(self: CellManager, player: Player): string?
	local occupiedCells = self.cellsPerPlayer[player]
	if not occupiedCells then
		return nil
	end

	return occupiedCells.locationStr
end

--

function CellManager.update(self: CellManager): ()
	-- O(*sodding terrible*)
	self:updateOverlapParams()
	self:recalculatePlayers()
	self:updatePlayersTrespassingStatus()
end

function CellManager.updateOverlapParams(self: CellManager): ()
	table.clear(self.playersRootPart)
	local validParts: { Instance } = {}

	for _, player in Players:GetPlayers() do
		if not CellManager.isPlayerValid(player) then
			self.cellsPerPlayer[player] = nil
			continue
		end

		-- we already checked if it has a root part in isPlayerValid()
		local rootPart = (player.Character :: any).HumanoidRootPart :: BasePart
		self.playersRootPart[rootPart] = player
		table.insert(validParts, rootPart)
	end

	self.currentOverlapParams.FilterDescendantsInstances = validParts
end

function CellManager.recalculatePlayers(self: CellManager): ()
	table.clear(self.cellsPerPlayer)

	for rootPart, player in self.playersRootPart do
		local pos = rootPart.Position
		for _, cell in self.cells do
			if isPosInCell(pos, cell) then
				self.cellsPerPlayer[player] = cell
				break
			end
		end
	end
end

function CellManager.updatePlayersTrespassingStatus(self: CellManager): ()
	for player, cell in self.cellsPerPlayer do
		-- Wait wha?
		local cellConfig = (self.cellConfigs[cell.name] :: any).config :: CellConfig.CellConfig
		if not cellConfig then
			continue
		end

		local playerStatus = PlayerStatusRegistry.getPlayerStatusHolder(player)
		if not playerStatus then
			continue
		end

		local disguise = playerStatus:getDisguise() or "None" -- Should be returned by the method itself but keep it for now
		local penalty: PlayerStatus.PlayerStatus?

		if cellConfig.trespass then
			penalty = PlayerStatusTypes.MAJOR_TRESPASSING
		end

		if cellConfig.minorTrespass and cellConfig.minorTrespass[disguise] then
			penalty = PlayerStatusTypes.MINOR_TRESPASSING
		end

		if cellConfig.allow and cellConfig.allow[disguise] then
			penalty = nil
		end

		local appliedPenalties: { [PlayerStatus.PlayerStatus]: true } = self.playerZonePenalties[player] or {}

		-- apply current penalty if applicable
		if penalty and not playerStatus:hasStatus(penalty) then
			playerStatus:addStatus(penalty)
		end

		-- remove penalties that are no longer relevant
		for appliedPenalty in appliedPenalties do
			if appliedPenalty ~= penalty then
				playerStatus:removeStatus(appliedPenalty)
				appliedPenalties[appliedPenalty] = nil
			end
		end

		if penalty then
			appliedPenalties[penalty] = true
		end

		self.playerZonePenalties[player] = appliedPenalties
	end

	-- also handle players who left all trespassable zones
	for player, appliedPenalties in self.playerZonePenalties do
		if self.cellsPerPlayer[player] then
			continue
		end

		local playerStatus = PlayerStatusRegistry.getPlayerStatusHolder(player)
		if not playerStatus then
			continue
		end

		for appliedPenalty in appliedPenalties do
			playerStatus:removeStatus(appliedPenalty)
		end

		self.playerZonePenalties[player] = nil
	end
end

--

function CellManager.isPlayerValid(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end

	if not PlayerStatusRegistry.playerHasStatuses(player) then
		return false
	end

	if not character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return (humanoid and humanoid.Health > 0) :: boolean
end

return CellManager