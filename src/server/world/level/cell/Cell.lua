--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local ZoneUtils = require(ServerScriptService.server.world.level.cell.util.ZoneUtils)
local CellConfig = require(script.Parent.CellConfig)

-- what in the actual heavenly fuck?
local cellsPerPlayer: { [Player]: Model } = {}
local playersRootPart: { [BasePart]: Player } = {}
local playerZonePenalties: { [Player]: { [PlayerStatus.PlayerStatus]: true } } = {}
local currentOverlapParams = OverlapParams.new()
currentOverlapParams.FilterType = Enum.RaycastFilterType.Include

-- TODO: Fix all of the bullshit in this code. Thank you.

--[=[
	@class Cell
]=]
local Cell = {}

function Cell.getCellConfig(cell: Model): CellConfig.Config?
	local required = (require :: any)(workspace.Level.MissionSetup)
	return (required and required.Cells) and required.Cells[cell.Name] or nil
end

function Cell.getPlayerOccupiedAreaName(player: Player): string?
	local cell = cellsPerPlayer[player]
	if not cell then
		return nil
	end

	local cellLocationSerialKey = cell:GetAttribute("Location") :: string?
	if not cellLocationSerialKey then
		return nil
	end
	local required = (require :: any)(workspace.Level.MissionSetup)
	local actualName = required.CustomStrings[cellLocationSerialKey]
	if not actualName then
		return "UNLOCALIZED_STRING"
	end

	return actualName
end

--

function Cell.update(): ()
	-- O(*sodding terrible*)
	Cell.updateOverlapParams()
	Cell.recalculatePlayers()
	Cell.updatePlayersTrespassingStatus()
end

function Cell.updateOverlapParams(): ()
	table.clear(playersRootPart)
	local validParts: { Instance } = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if not Cell.isPlayerValid(player) then
			cellsPerPlayer[player] = nil
			continue
		end

		-- we already checked if it has a root part in isPlayerValid()
		local rootPart = (player.Character :: any).HumanoidRootPart :: BasePart
		playersRootPart[rootPart] = player
		table.insert(validParts, rootPart)
	end

	currentOverlapParams.FilterDescendantsInstances = validParts
end

function Cell.recalculatePlayers(): ()
	table.clear(cellsPerPlayer)
	
	local cells = workspace.Level.Cells:GetChildren() :: { Model }

	for rootPart, player in pairs(playersRootPart) do
		local pos = rootPart.Position
		for _, cell in ipairs(cells) do
			if ZoneUtils.isPosInZone(pos, cell) then
				cellsPerPlayer[player] = cell
				break
			end
		end
	end
end

function Cell.updatePlayersTrespassingStatus(): ()
	for player, cell in pairs(cellsPerPlayer) do
		local cellConfig = Cell.getCellConfig(cell)
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

		local appliedPenalties: { [PlayerStatus.PlayerStatus]: true } = playerZonePenalties[player] or {}

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
		if cellsPerPlayer[player] then
			continue
		end

		local playerStatus = PlayerStatusRegistry.getPlayerStatusHolder(player)
		if not playerStatus then
			continue
		end

		for appliedPenalty in pairs(appliedPenalties) do
			playerStatus:removeStatus(appliedPenalty)
		end
		playerZonePenalties[player] = nil
	end
end

--

function Cell.isPlayerValid(player: Player): boolean
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

return Cell