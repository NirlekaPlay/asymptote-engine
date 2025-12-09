--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local ACTION_NAME_LEFT = "ACTION_SPECTATE_CYCLE_LEFT"
local ACTION_NAME_RIGHT = "ACTION_SPECTATE_CYCLE_RIGHT"
local ACTION_NAME_STOP = "ACTION_SPECTATE_STOP"
local ACTION_KEYCODE_LEFT = Enum.KeyCode.Q
local ACTION_KEYCODE_RIGHT = Enum.KeyCode.E

local LocalPlayer = Players.LocalPlayer
local currentIndex = 1
local isSpectating = false

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
		return
	end

	local targetCharacter = targetPlayer.Character
	local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")

	if targetHumanoid then
		camera.CameraType = Enum.CameraType.Orbital 
		camera.CameraSubject = targetHumanoid

		isSpectating = true
	else
		Spectate.cycleSpectate(true) 
	end
end

function Spectate.enableMode(): ()
	ContextActionService:BindAction(ACTION_NAME_LEFT, Spectate.onInputCycleSpectate, false, ACTION_KEYCODE_LEFT)
	ContextActionService:BindAction(ACTION_NAME_RIGHT, Spectate.onInputCycleSpectate, false, ACTION_KEYCODE_RIGHT)
	ContextActionService:BindAction(ACTION_NAME_STOP, Spectate.onInputCycleSpectate, false, ACTION_KEYCODE_RIGHT)
end

function Spectate.disableMode(): ()
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

return Spectate