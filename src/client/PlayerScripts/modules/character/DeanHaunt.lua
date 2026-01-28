--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BoundingBox = require(ReplicatedStorage.shared.util.math.geometry.BoundingBox)

local DeanHaunt = {}

local rng = Random.new()
local CHARACTER = ReplicatedStorage:FindFirstChild("Dean") :: Model
local SPAWN_CHANCE = 0.001
local MIN_SPAWN_COOLDOWN = 30
local MAX_SPAWN_COOLDOWN = 60
local MIN_SPAWN_DISTANCE = 5
local MAX_SPAWN_DISTANCE = 15
local DESPAWN_SPEED = 0.3
local DISAPPEAR_SOUND = ReplicatedStorage.shared.assets.sounds.events.heavy_fast_breathing
local HANGING_AROUND_SOUND = ReplicatedStorage.shared.assets.sounds.gunsys.heartbeat_96bpm
local HANGING_AROUND_SOUND_MAX_VOLUME = 1.5
local HANGING_AROUND_SOUND_RAMP_SPEED = 0.5 -- per sec
local SPAWN_SOUND = ReplicatedStorage.shared.assets.sounds.events.dean_spawn
local SPAWN_SOUND_MIN_PLAYBACK_SPEED = 1
local SPAWN_SOUND_MAX_PLAYBACK_SPEED = 4

local camera = (workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")) :: Camera
local characterToCheck: Model? = nil
local activeSpook: Model? = nil
local activeSpookCorners: {Vector3}? = nil
local updateConnection: RBXScriptConnection? = nil
local characterConnection: RBXScriptConnection? = nil
local isActive = false
local lastTimeSpawned = os.clock()
local currentSpawnCooldown = rng:NextNumber(MIN_SPAWN_COOLDOWN, MAX_SPAWN_COOLDOWN)

function DeanHaunt.initialize()
	if isActive then return end
	isActive = true
	
	local player = Players.LocalPlayer
	if not player then return end

	characterConnection = player.CharacterAppearanceLoaded:Connect(function(character)
		if isActive then
			DeanHaunt.startSpookCheck(character)
		end
	end)

	if player.Character then
		DeanHaunt.startSpookCheck(player.Character)
	end
end

function DeanHaunt.stop()
	if not isActive then return end
	isActive = false
	
	if characterConnection then
		characterConnection:Disconnect()
		characterConnection = nil
	end
	
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end
	
	if HANGING_AROUND_SOUND.IsPlaying then
		HANGING_AROUND_SOUND:Stop()
	end
	
	if activeSpook then
		if activeSpook.Parent then
			activeSpook:Destroy()
		end
		activeSpook = nil
		activeSpookCorners = nil
	end
	
	characterToCheck = nil
end

function DeanHaunt.isRunning(): boolean
	return isActive
end

function DeanHaunt.startSpookCheck(character: Model): ()
	if not isActive then return end
	
	characterToCheck = character
	if updateConnection then
		updateConnection:Disconnect()
	end
	updateConnection = RunService.Heartbeat:Connect(DeanHaunt.update)
end

function DeanHaunt.update(deltaTime: number): ()
	if not isActive then
		DeanHaunt.stop()
		return
	end
	
	local character = characterToCheck
	local humanoidRootPart: BasePart
	if not character or not character.Parent then
		if updateConnection then
			characterToCheck = nil
			updateConnection:Disconnect()
			updateConnection = nil
		end
		return
	else
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			if updateConnection then
				characterToCheck = nil
				updateConnection:Disconnect()
				updateConnection = nil
			end
			return
		end
		humanoidRootPart = root
	end

	if DeanHaunt.canSpawn() then
		DeanHaunt.spawnBehindPlayerIfPossible(humanoidRootPart)
	end

	if activeSpook then
		local isOnScreen = DeanHaunt.checkIfOnScreen(activeSpook)
		if isOnScreen then
			HANGING_AROUND_SOUND:Stop()
			DeanHaunt.disappear(activeSpook)
			return
		else
			DeanHaunt.turnToCharacter(activeSpook, characterToCheck)
		end
		if not HANGING_AROUND_SOUND.IsPlaying then
			HANGING_AROUND_SOUND.Volume = 0
			HANGING_AROUND_SOUND:Play()
		end
		HANGING_AROUND_SOUND.Volume = math.clamp(
			HANGING_AROUND_SOUND.Volume + HANGING_AROUND_SOUND_RAMP_SPEED * deltaTime,
			0,
			HANGING_AROUND_SOUND_MAX_VOLUME
		)
	end
end

function DeanHaunt.spawnBehindPlayerIfPossible(rootPart: BasePart): ()
	if not isActive then return end
	
	local cameraCFrame = camera.CFrame
	local lookVector = cameraCFrame.LookVector
	local behindVector = -lookVector

	-- flatten to horizontal plane (ignore vertical)
	local flatVector = Vector3.new(behindVector.X, 0, behindVector.Z).Unit
	local spawnDistance = rng:NextNumber(MIN_SPAWN_DISTANCE, MAX_SPAWN_DISTANCE)

	-- spawn point starts behind the camera
	local spawnOrigin = cameraCFrame.Position + flatVector * spawnDistance

	local rayOrigin = spawnOrigin + Vector3.new(0, 50, 0)  -- start high above
	local rayDirection = Vector3.new(0, -100, 0)           -- cast down

	local player = Players.LocalPlayer
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character :: Model}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if raycastResult then
		local spawnPosition = raycastResult.Position
		local lookAtPlayer = CFrame.lookAt(spawnPosition, rootPart.Position)
		local spookModel = CHARACTER:Clone()
		spookModel:PivotTo(lookAtPlayer)
		local cframe, size = spookModel:GetBoundingBox()
		
		-- Offset upward by half the model's height to avoid sinking
		local offsetPosition = spawnPosition + Vector3.new(0, size.Y / 2, 0)
		spookModel:PivotTo(CFrame.lookAt(offsetPosition, rootPart.Position))
		
		activeSpook = spookModel
		activeSpookCorners = BoundingBox.getCornersFromBoundingBox(cframe, size)
		spookModel.Parent = workspace
		lastTimeSpawned = os.clock()
		DeanHaunt.playSound(SPAWN_SOUND, SPAWN_SOUND_MIN_PLAYBACK_SPEED, SPAWN_SOUND_MAX_PLAYBACK_SPEED)
	end
end

function DeanHaunt.turnToCharacter(spookModel: Model, toChar: Model?): ()
	if not toChar then
		return
	end

	local primaryPart = toChar.PrimaryPart
	if not primaryPart then
		return
	end

	local spookModelPivot = spookModel:GetPivot()
	spookModel:PivotTo(CFrame.lookAt(spookModelPivot.Position, primaryPart.Position))
end

function DeanHaunt.checkIfOnScreen(spookModel: Model): boolean
	if not activeSpookCorners then
		error("ACTIVE_CORNERS_NIL")
	end
	local isInView = BoundingBox.isBoundingBoxInViewByViewportCorners(BoundingBox.getViewportCorners(activeSpookCorners, camera))
	return isInView
end

function DeanHaunt.playSound(sound: Sound, minPlaySpeed: number?, maxPlaySpeed: number?, dontPlayIfAlr: boolean?): ()
	if minPlaySpeed and maxPlaySpeed then
		sound.PlaybackSpeed = rng:NextNumber(minPlaySpeed, maxPlaySpeed)
	end
	if sound.IsPlaying and dontPlayIfAlr then
		return
	end
	sound:Play()
end

function DeanHaunt.canSpawn(): boolean
	if not isActive then return false end
	local timeDiff = os.clock() - lastTimeSpawned
	local random = rng:NextNumber(0, 1)
	local randomChance = random < SPAWN_CHANCE
	return not activeSpook and
		randomChance and
		timeDiff >= currentSpawnCooldown
end

function DeanHaunt.disappear(spookModel: Model): ()
	activeSpook = nil
	activeSpookCorners = nil

	task.spawn(function()
		task.wait(DESPAWN_SPEED)
		if spookModel and spookModel.Parent then
			spookModel:Destroy()
		end
		DeanHaunt.playSound(DISAPPEAR_SOUND, nil, nil, true)
	end)
end

return DeanHaunt