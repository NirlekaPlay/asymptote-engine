--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local CoreCall = require(StarterPlayer.StarterPlayerScripts.client.modules.util.CoreCall)

local ACTION_NAME_LEFT = "ACTION_SPECTATE_CYCLE_LEFT"
local ACTION_NAME_RIGHT = "ACTION_SPECTATE_CYCLE_RIGHT"
local ACTION_NAME_STOP = "ACTION_SPECTATE_STOP"
local ACTION_KEYCODE_LEFT = Enum.KeyCode.Q
local ACTION_KEYCODE_RIGHT = Enum.KeyCode.E
local ACTION_KEYCODE_STOP = Enum.KeyCode.Space

local LocalPlayer = Players.LocalPlayer
local currentIndex = 1
local isSpectating = false

local spectateGui = ReplicatedStorage.shared.assets.gui.Spectate

--[=[
	@class Spectate
]=]
local Spectate = {}

function Spectate.startSpectate(): ()
	local validSortedPlayers = Spectate.getValidPlayers()
	if #validSortedPlayers > 0 then
		Spectate.spectateTarget(validSortedPlayers[currentIndex]) 
	else
		print("No valid players to spectate.")
	end
end

function Spectate.onInputCycleSpectate(
	actionName: string, inputState: Enum.UserInputState, inputObj: InputObject
): Enum.ContextActionResult?

	if inputState ~= Enum.UserInputState.Begin then
		return nil
	end

	if actionName == ACTION_NAME_LEFT then
		Spectate.cycleSpectate(false)
	elseif actionName == ACTION_NAME_RIGHT then
		Spectate.cycleSpectate(true)
	elseif actionName == ACTION_NAME_STOP and isSpectating then
		Spectate.spectateTarget(nil)
	end

	return nil
end

function Spectate.cycleSpectate(add: boolean): ()
	local validSortedPlayers = Spectate.getValidPlayers()
	local playerCount = #validSortedPlayers

	if playerCount == 0 then
		Spectate.spectateTarget(nil) -- No one to spectate
		return
	end

	currentIndex += add and 1 or -1

	if currentIndex > playerCount then
		currentIndex = 1
	elseif currentIndex < 1 then
		currentIndex = playerCount
	end

	local target = validSortedPlayers[currentIndex]

	Spectate.spectateTarget(target)
end

function Spectate.spectateTarget(targetPlayer: Player?): ()
	local camera = workspace.CurrentCamera
	if not targetPlayer then
		-- TODO: CameraManager should handle this probably for centralization.
		camera.CameraType = Enum.CameraType.Custom
		local localHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		camera.CameraSubject = localHumanoid
		isSpectating = false
		Spectate.updateSpectateGui(nil)
		return
	end

	local targetCharacter = targetPlayer.Character
	local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")

	if targetHumanoid then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = targetHumanoid

		isSpectating = true
	else
		Spectate.cycleSpectate(true) 
	end

	Spectate.updateSpectateGui(targetPlayer)
end

function Spectate.enableMode(): ()
	Spectate.startSpectate()
	ContextActionService:BindAction(ACTION_NAME_LEFT, Spectate.onInputCycleSpectate, false, ACTION_KEYCODE_LEFT)
	ContextActionService:BindAction(ACTION_NAME_RIGHT, Spectate.onInputCycleSpectate, false, ACTION_KEYCODE_RIGHT)
	ContextActionService:BindAction(ACTION_NAME_STOP, Spectate.onInputCycleSpectate, false, ACTION_KEYCODE_STOP)
end

function Spectate.disableMode(): ()
	Spectate.spectateTarget(nil)
	ContextActionService:UnbindAction(ACTION_NAME_LEFT)
	ContextActionService:UnbindAction(ACTION_NAME_RIGHT)
	ContextActionService:UnbindAction(ACTION_NAME_STOP)
end

function Spectate.getValidPlayers(): { Player }
	local players = Players:GetPlayers()
	local sortedPlayersList: { Player } = {}
	local count = 0

	for _, player in players do
		if player == LocalPlayer then
			continue
		end

		local playerChar = player.Character
		if not playerChar or not playerChar:IsDescendantOf(workspace) then
			continue
		end

		local humanoid = playerChar:FindFirstChildOfClass("Humanoid")
		if not humanoid then 
			continue
		end

		count += 1
		sortedPlayersList[count] = player
	end

	table.sort(sortedPlayersList, function(p1: Player, p2: Player)
		return p1.Name < p2.Name
	end)

	return sortedPlayersList
end

--

function Spectate.updateSpectateGui(spectateTarget: Player?): ()
	-- TODO: Maybe update the key icons as well.
	local gui = Spectate.getSpectateGui()
	
	if spectateTarget then
		if not gui.Enabled then
			gui.Enabled = true
		end

		gui.Root.Frame.PlayerName.Text = spectateTarget.Name
		-- TODO: Should be handled in another module.
		CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.Backpack, false)
	else
		gui.Enabled = false
		CoreCall.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.Backpack, true)
	end
end

function Spectate.getSpectateGui(): typeof(spectateGui)
	local existing = LocalPlayer.PlayerGui:FindFirstChild(spectateGui.Name)
	if not existing then
		local new = spectateGui:Clone()
		new.Enabled = false
		new.Parent = LocalPlayer.PlayerGui
		return new
	end

	return existing :: any
end

return Spectate