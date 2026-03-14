--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AccessoryFiltering = require(ReplicatedStorage.shared.gunsys.framework.filtering.AccessoryFiltering)

local function safePlayerAdded(callback: (Player) -> ()): RBXScriptConnection
	for _, player in Players:GetPlayers() do
		task.spawn(callback, player)
	end

	return Players.PlayerAdded:Connect(callback)
end

local function onCharacterAdded(character: Model): ()
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	AccessoryFiltering.proccessCharacter(character)
end

local function onPlayerAdded(player: Player): ()
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

safePlayerAdded(onPlayerAdded)