--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local TypedRemotes = require(ReplicatedStorage.shared.network.TypedRemotes)
local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera
local currentCharacter: Model?

local ORIGINAL_NECK_C0 = CFrame.new(0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
local VERTICAL_FACTOR = 0.6
local HORIZONTAL_FACTOR = 1.5
local ROTATION_SPEED = 0.3
local HEAD_ROTATION_REMOTE = TypedRemotes.PlayerHeadRotationServer
local HEAD_ROTATION_REMOTE_CLIENT = TypedRemotes.PlayerHeadRotationClient
local REMOTE_UPDATE_PER_SECOND = 10
local REMOTE_UPDATE_INTERVAL = 1 / REMOTE_UPDATE_PER_SECOND

local playersCameraPos: { [Player]: Vector3 } = {}
local playersDiedConnections: { [Player]: RBXScriptConnection } = {}
local lastSentCameraPos: Vector3? = nil

local function updateHeadRotation(character: Model, cameraPos: Vector3?)
	local head = character:FindFirstChild("Head") :: BasePart
	local torso = character:FindFirstChild("Torso") :: BasePart
	local neck = torso:FindFirstChild("Neck") :: Motor6D
	local speed = ROTATION_SPEED

	local finalWantedCframe = ORIGINAL_NECK_C0

	local pos = cameraPos or currentCamera.CFrame.Position
	local distance = (head.CFrame.Position - pos).Magnitude
	local difference = head.CFrame.Y - pos.Y

	local diffUnit = ((head.Position - pos).Unit)
	local torsoLV = torso.CFrame.LookVector

	local angle = CFrame.Angles(
		-math.asin(difference / distance) * VERTICAL_FACTOR,
		0,
		-diffUnit:Cross(torsoLV).Y * HORIZONTAL_FACTOR
	)

	finalWantedCframe *= angle
	neck.C0 = neck.C0:Lerp(finalWantedCframe, speed / 2)
end

local function updatePlayersHeadRotation()
	for player, cameraPos in pairs(playersCameraPos) do
		if not player.Character then continue end

		updateHeadRotation(player.Character, cameraPos)
	end
end

local function disconnectPlayerDiedConnection(player: Player)
	if playersDiedConnections[player] then
		playersDiedConnections[player]:Disconnect()
	end
end

local function connectPlayerDiedConnection(player: Player)
	if not player.Character then return end
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid") :: Humanoid
	disconnectPlayerDiedConnection(player)

	playersDiedConnections[player] = humanoid.Died:Once(function()
		playersDiedConnections[player] = nil
		if player == localPlayer then
			currentCharacter = nil
		else
			playersCameraPos[player] = nil
		end
	end)
end

if localPlayer.Character then
	currentCharacter = localPlayer.Character
	connectPlayerDiedConnection(localPlayer)
end

localPlayer.CharacterAdded:Connect(function(character)
	currentCharacter = localPlayer.Character
	connectPlayerDiedConnection(localPlayer)
end)

localPlayer.CharacterRemoving:Connect(function()
	currentCharacter = nil
	disconnectPlayerDiedConnection(localPlayer)
end)

Players.PlayerRemoving:Connect(function(player)
	playersCameraPos[player] = nil
	disconnectPlayerDiedConnection(player)
end)

HEAD_ROTATION_REMOTE_CLIENT.OnClientEvent:Connect(function(player, cameraPos)
	if player == localPlayer then return end
	if not player.Character then return end

	playersCameraPos[player] = cameraPos
end)

local timeAccum = 0
RunService.RenderStepped:Connect(function(deltaTime)
	if not currentCharacter then
		return
	end

	updateHeadRotation(currentCharacter)
	updatePlayersHeadRotation()

	timeAccum -= deltaTime
	if timeAccum <= 0 then
		timeAccum = REMOTE_UPDATE_INTERVAL
		if not lastSentCameraPos or (lastSentCameraPos - currentCamera.CFrame.Position).Magnitude > 0.1 then
			lastSentCameraPos = currentCamera.CFrame.Position
			HEAD_ROTATION_REMOTE:FireServer(lastSentCameraPos :: Vector3)
		end
	end
end)
