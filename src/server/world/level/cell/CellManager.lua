--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local LevelInstancesAccessor = require(ServerScriptService.server.world.level.LevelInstancesAccessor)
local CellConfig = require(ServerScriptService.server.world.level.cell.CellConfig)
local ZoneUtils = require(ServerScriptService.server.world.level.cell.util.ZoneUtils)
local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)

--[=[
	@class CellManager
]=]
local CellManager = {}
CellManager.__index = CellManager

export type CellManager = typeof(setmetatable({} :: {
	cellsPerPlayer: { [Player]: Model },
	playersRootPart: { [BasePart]: Player },
	playerZonePenalties: { [Player]: { [PlayerStatus.PlayerStatus]: true } },
	serverLevelInstancesAccessor: LevelInstancesAccessor.LevelInstancesAccessor,
	currentOverlapParams: OverlapParams
}, CellManager))

function CellManager.new(levelInstancesAccessor: LevelInstancesAccessor.LevelInstancesAccessor): CellManager
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	return setmetatable({
		cellsPerPlayer = {},
		playersRootPart = {},
		playerZonePenalties = {},
		serverLevelInstancesAccessor = levelInstancesAccessor,
		currentOverlapParams = overlapParams
	}, CellManager)
end

function CellManager.getCellManagerConfig(self: CellManager, cell: Model): CellConfig.Config?
	local missionSetup = self:getServerLevelInstancesAccessor():getMissionSetup()
	return missionSetup:getCellConfig(cell.Name) or nil
end

function CellManager.getServerLevelInstancesAccessor(self: CellManager): LevelInstancesAccessor.LevelInstancesAccessor
	return self.serverLevelInstancesAccessor
end

function CellManager.getPlayerOccupiedAreaName(self: CellManager, player: Player): string?
	local occupiedCells = self.cellsPerPlayer[player]
	if not occupiedCells then
		return nil
	end

	local cellLocationLocalizedKey = occupiedCells:GetAttribute("Location") :: string?
	if not cellLocationLocalizedKey then
		return nil
	end

	return self:getServerLevelInstancesAccessor():getMissionSetup():getLocalizedString(cellLocationLocalizedKey)
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

	for _, player in ipairs(Players:GetPlayers()) do
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
	
	local cellModels = self:getServerLevelInstancesAccessor():getCellModels()

	for rootPart, player in pairs(self.playersRootPart) do
		local pos = rootPart.Position
		for _, cell in ipairs(cellModels) do
			if ZoneUtils.isPosInZone(pos, cell) then
				self.cellsPerPlayer[player] = cell
				break
			end
		end
	end
end

function CellManager.updatePlayersTrespassingStatus(self: CellManager): ()
	for player, cell in pairs(self.cellsPerPlayer) do
		local cellConfig = self:getCellManagerConfig(cell)
		if not cellConfig or not cellConfig.canBeTrespassed then
			continue
		end

		local playerStatus = PlayerStatusRegistry.getPlayerStatusHolder(player)
		if not playerStatus then
			continue
		end

		local disguised = playerStatus:hasStatus(PlayerStatusTypes.DISGUISED)
		local penalty: PlayerStatus.PlayerStatus?

		if disguised then
			penalty = cellConfig.penalties.disguised
		else
			penalty = cellConfig.penalties.undisguised
		end

		local appliedPenalties: { [PlayerStatus.PlayerStatus]: true } = self.playerZonePenalties[player] or {}

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

		self.playerZonePenalties[player] = appliedPenalties
	end

	-- also handle players who left all trespassable zones
	for player, appliedPenalties in pairs(self.playerZonePenalties) do
		if self.cellsPerPlayer[player] then
			continue
		end

		local playerStatus = PlayerStatusRegistry.getPlayerStatusHolder(player)
		if not playerStatus then
			continue
		end

		for appliedPenalty in pairs(appliedPenalties) do
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