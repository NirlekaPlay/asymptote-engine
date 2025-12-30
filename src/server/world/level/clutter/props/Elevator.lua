--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Bounds = require(ReplicatedStorage.shared.math.geometry.Bounds)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local Prop = require(ServerScriptService.server.world.level.clutter.props.Prop)

local TIME_TO_OPEN_DOORS = 2
local TWEEN_INFO = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local DOOR_OFFSET = Vector3.new(4, 0, 0) -- Distance doors slide apart
local STATES = {
	IDLE = 0,
	DOORS_OPENED = 1,
	DOORS_OPENING = 2,
	DOORS_CLOSED = 3,
	DOORS_CLOSING = 4
}

local function weld(part0: BasePart, part1: BasePart): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part1
	return weld
end

local function createPrimaryPartFromModel(model: Model): ()
	local cframe, size = model:GetBoundingBox()

	local primaryPart = Instance.new("Part")
	primaryPart.Transparency = 1
	primaryPart.CanCollide = false
	primaryPart.AudioCanCollide = false
	primaryPart.CanQuery = false
	primaryPart.Size = size
	primaryPart.CFrame = cframe
	primaryPart.Anchored = true

	for _, child in model:GetChildren() do
		if child:IsA("BasePart") then
			child.Anchored = false
			child.Parent = primaryPart

			weld(child, primaryPart)
		end
	end

	primaryPart.Parent = model
	model.PrimaryPart = primaryPart
end

--[=[
	@class Elevator
]=]
local Elevator = {}
Elevator.__index = Elevator

export type Elevator = Prop.Prop & typeof(setmetatable({} :: {
	doorLeft: Model,
	doorRight: Model,
	ceilingLightPart: BasePart,
	ceilingPointLight: PointLight,
	bounds: { cframe: CFrame, size: Vector3 },
	--
	openDoorsTimer: number,
	currentState: number,
	--
	soundDing: Sound
}, Elevator))

function Elevator.createFromPlaceholder(
	placeholder: BasePart,
	model: Model?,
	serverLevel: ServerLevel.ServerLevel
): Prop.Prop

	if not model then
		error(`Attempt to create Elevator with no passed model`)
	end

	local doorLeft = (model :: any).ElevatorDoor0 :: Model
	local doorRight = (model :: any).ElevatorDoor1 :: Model

	local cframe, size = model:GetBoundingBox()
	local bounds = { cframe = cframe, size = size }

	createPrimaryPartFromModel(doorLeft)
	createPrimaryPartFromModel(doorRight)

	local ceilingLightPart = (model :: any).LightNight :: BasePart
	ceilingLightPart.Transparency = 0.55

	local ceilingPointLight = Instance.new("PointLight")
	ceilingPointLight.Parent = ceilingLightPart

	

	local dingSound = ReplicatedStorage.shared.assets.sounds.props.elevator_ding:Clone()
	dingSound.Volume = 0.1
	dingSound.Parent = doorLeft.PrimaryPart :: BasePart

	local self = setmetatable({
		doorLeft = doorLeft,
		doorRight = doorRight,
		ceilingLightPart = ceilingLightPart,
		ceilingPointLight = ceilingPointLight,
		bounds = bounds,
		--
		openDoorsTimer = TIME_TO_OPEN_DOORS,
		currentState = STATES.DOORS_CLOSED,
		soundDing = dingSound
	}, Elevator) :: Elevator

	self:turnOnCeilingLight()

	return self
end

function Elevator.turnOnCeilingLight(self: Elevator): ()
	self.ceilingLightPart.Material = Enum.Material.Neon
	self.ceilingPointLight.Enabled = true
end

function Elevator.turnOffCeilingLight(self: Elevator): ()
	self.ceilingLightPart.Material = Enum.Material.SmoothPlastic
	self.ceilingPointLight.Enabled = false
end

function Elevator.openDoors(self: Elevator): ()
	if self.currentState == STATES.DOORS_OPENING or self.currentState == STATES.DOORS_OPENED then
		return
	end

	self.currentState = STATES.DOORS_OPENING

	local leftTarget = self.doorLeft:GetPivot() * CFrame.new(-DOOR_OFFSET)
	local rightTarget = self.doorRight:GetPivot() * CFrame.new(DOOR_OFFSET)

	local tweenL = TweenService:Create(self.doorLeft.PrimaryPart, TWEEN_INFO, {CFrame = leftTarget})
	local tweenR = TweenService:Create(self.doorRight.PrimaryPart, TWEEN_INFO, {CFrame = rightTarget})

	tweenL:Play()
	tweenR:Play()

	tweenL.Completed:Once(function()
		if self.currentState == STATES.DOORS_OPENING then
			self.currentState = STATES.DOORS_OPENED
		end
	end)
end

function Elevator.closeDoors(self: Elevator): ()
	if self.currentState == STATES.DOORS_CLOSING or self.currentState == STATES.DOORS_CLOSED then
		return
	end

	self.currentState = STATES.DOORS_CLOSING

	local leftTarget = self.doorLeft:GetPivot() * CFrame.new(DOOR_OFFSET)
	local rightTarget = self.doorRight:GetPivot() * CFrame.new(-DOOR_OFFSET)

	local tweenL = TweenService:Create(self.doorLeft.PrimaryPart, TWEEN_INFO, {CFrame = leftTarget})
	local tweenR = TweenService:Create(self.doorRight.PrimaryPart, TWEEN_INFO, {CFrame = rightTarget})

	tweenL:Play()
	tweenR:Play()

	tweenL.Completed:Once(function()
		if self.currentState == STATES.DOORS_CLOSING then
			self.currentState = STATES.DOORS_CLOSED
		end
	end)
end

function Elevator.forceCloseDoors(self: Elevator): ()
	self.currentState = STATES.DOORS_CLOSED

	local leftTarget = self.doorLeft:GetPivot() * CFrame.new(DOOR_OFFSET)
	local rightTarget = self.doorRight:GetPivot() * CFrame.new(-DOOR_OFFSET);

	(self.doorLeft.PrimaryPart :: BasePart).CFrame = leftTarget;
	(self.doorRight.PrimaryPart :: BasePart).CFrame = rightTarget

	self.openDoorsTimer = TIME_TO_OPEN_DOORS
end

function Elevator.update(self: Elevator, deltaTime: number, serverLevel: ServerLevel.ServerLevel): ()
	local isAnyPlayersInElev = false

	for _, player in Players:GetPlayers() do
		local plrChar = player.Character 
		if not plrChar then
			continue
		end

		local humanoidRootPart = plrChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoidRootPart then
			continue
		end

		-- No check for humanoid, let dead players be counted as well,
		-- so that when the elevator opens all they find is a dead body >:D

		local isInBounds = Bounds.isPosInBounds(
			humanoidRootPart.Position,
			self.bounds.cframe,
			self.bounds.size
		)

		if isInBounds then
			isAnyPlayersInElev = true
			break
		end
	end

	if isAnyPlayersInElev then
		if self.openDoorsTimer > 0 then
			self.openDoorsTimer -= deltaTime
		end
	else
		if self.openDoorsTimer < TIME_TO_OPEN_DOORS then
			self.openDoorsTimer += deltaTime
		end
	end

	if self.openDoorsTimer <= 0 then
		if self.currentState == STATES.DOORS_CLOSED then
			self.soundDing:Play()
			self:openDoors()
		end
	elseif self.openDoorsTimer >= TIME_TO_OPEN_DOORS then
		if self.currentState ~= STATES.DOORS_CLOSED then
			self:closeDoors()
		end
	end
end

function Elevator.onLevelRestart(self: Elevator, serverLevel: ServerLevel.ServerLevel): ()
	self:forceCloseDoors()
end

return Elevator