--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera

local ADJUSTING_MODE_ATTRIBUTE_NAME = "PlayerHeadRotationAdjustingMode"
local ADJUSTING_MODE = StarterPlayer:GetAttribute(ADJUSTING_MODE_ATTRIBUTE_NAME)
local ADJUSTING_MODE_VERTICAL_FACTOR_ATTRIBUTE_NAME = "VerticalFactor"
local ADJUSTING_MODE_HORIZONTAL_FACTOR_ATTRIBUTE_NAME = "HorizontalFactor"
local ADJUSTING_MODE_ROTATION_SPEED_ATTRIBUTE_NAME = "RotationSpeed"
local ORIGINAL_NECK_C0 = CFrame.new(0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
local VERTICAL_FACTOR = 0.6
local HORIZONTAL_FACTOR = 1
local ROTATION_SPEED = 0.3
local HEAD_ROTATION_REMOTE_SERVER = TypedRemotes.PlayerHeadRotationServer
local SEND_LOCAL_PLAYER_CAMERA_POS_PER_SECOND = 10
local SEND_LOCAL_PLAYER_CAMERA_POS_INTERVAL = 1 / SEND_LOCAL_PLAYER_CAMERA_POS_PER_SECOND

local playersPerCameraPos: { [Player]: Vector3 } = {}
local lastSentCameraPos: Vector3? = nil
local timeAccum = 0

--[=[
	@class PlayerHeadRotation
]=]
local PlayerHeadRotation = {}

function PlayerHeadRotation.addOrUpdatePlayersCameraPos(player: Player, cameraPos: Vector3): ()
	if PlayerHeadRotation.isValidPlayer(player) then
		playersPerCameraPos[player] = cameraPos
	end
end

function PlayerHeadRotation.isValidPlayer(player: Player): boolean
	if not player then
		return false
	end

	if not player:IsDescendantOf(Players) then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	if not character:FindFirstChild("Head") then
		return false
	end

	local torso = character:FindFirstChild("Torso")
	if not torso then
		return false
	end

	local neck = torso:FindFirstChild("Neck")
	if not neck then
		return false
	end

	return true
end

function PlayerHeadRotation.update(deltaTime: number): ()
	PlayerHeadRotation.removeInvalidPlayerCharacters()
	PlayerHeadRotation.updatePlayersHeadRotation(deltaTime)
end

function PlayerHeadRotation.removeInvalidPlayerCharacters(): ()
	for player, _ in pairs(playersPerCameraPos) do
		if not PlayerHeadRotation.isValidPlayer(player) then
			PlayerHeadRotation.cleanupPlayer(player)
		end
	end
end

function PlayerHeadRotation.cleanupPlayer(player: Player): ()
	playersPerCameraPos[player] = nil
end

function PlayerHeadRotation.updatePlayersHeadRotation(deltaTime: number): ()
	for player, camerapPos in pairs(playersPerCameraPos) do
		PlayerHeadRotation.updateHeadRotation(player.Character :: Model, camerapPos)
		if player == localPlayer then
			PlayerHeadRotation.sendLocalPlayerCameraPosToOtherClients(deltaTime)
		end
	end
end

function PlayerHeadRotation.updateHeadRotation(character: Model, cameraPos: Vector3): ()
	local head = character:FindFirstChild("Head") :: BasePart
	local torso = character:FindFirstChild("Torso") :: BasePart
	local neck = torso:FindFirstChild("Neck") :: Motor6D

	local distance = (head.CFrame.Position - cameraPos).Magnitude
	local difference = head.CFrame.Y - cameraPos.Y

	local diffUnit = ((head.Position - cameraPos).Unit)
	local torsoLV = torso.CFrame.LookVector

	local angle = CFrame.Angles(
		-math.asin(difference / distance) * VERTICAL_FACTOR,
		0,
		-diffUnit:Cross(torsoLV).Y * HORIZONTAL_FACTOR
	)

	neck.C0 = neck.C0:Lerp(ORIGINAL_NECK_C0 * angle, ROTATION_SPEED / 2)
end

function PlayerHeadRotation.sendLocalPlayerCameraPosToOtherClients(deltaTime: number): ()
	if #Players:GetPlayers() <= 1 then
		return
	end

	timeAccum -= deltaTime
	if timeAccum <= 0 then
		timeAccum = SEND_LOCAL_PLAYER_CAMERA_POS_INTERVAL
		if not lastSentCameraPos
			or (lastSentCameraPos - currentCamera.CFrame.Position).Magnitude > 0.1 then

			lastSentCameraPos = currentCamera.CFrame.Position
			HEAD_ROTATION_REMOTE_SERVER:FireServer(lastSentCameraPos :: Vector3)
		end
	end
end

if ADJUSTING_MODE then
	warn("Adjusting mode for PlayerHeadRotation is enabled.")
	warn("Adjust attributes on StarterPlayer.")

	StarterPlayer:SetAttribute(
		ADJUSTING_MODE_HORIZONTAL_FACTOR_ATTRIBUTE_NAME, HORIZONTAL_FACTOR
	)
	
	StarterPlayer:SetAttribute(
		ADJUSTING_MODE_VERTICAL_FACTOR_ATTRIBUTE_NAME, VERTICAL_FACTOR
	)

	StarterPlayer:SetAttribute(
		ADJUSTING_MODE_ROTATION_SPEED_ATTRIBUTE_NAME, ROTATION_SPEED
	)

	StarterPlayer:GetAttributeChangedSignal(ADJUSTING_MODE_HORIZONTAL_FACTOR_ATTRIBUTE_NAME):Connect(function()
		HORIZONTAL_FACTOR = StarterPlayer:GetAttribute(ADJUSTING_MODE_HORIZONTAL_FACTOR_ATTRIBUTE_NAME)
	end)
	
	StarterPlayer:GetAttributeChangedSignal(ADJUSTING_MODE_VERTICAL_FACTOR_ATTRIBUTE_NAME):Connect(function()
		VERTICAL_FACTOR = StarterPlayer:GetAttribute(ADJUSTING_MODE_VERTICAL_FACTOR_ATTRIBUTE_NAME)
	end)

	StarterPlayer:GetAttributeChangedSignal(ADJUSTING_MODE_ROTATION_SPEED_ATTRIBUTE_NAME):Connect(function()
		ROTATION_SPEED = StarterPlayer:GetAttribute(ADJUSTING_MODE_ROTATION_SPEED_ATTRIBUTE_NAME)
	end)
end

return PlayerHeadRotation