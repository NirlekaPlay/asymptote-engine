--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Door = require(ServerScriptService.server.world.level.clutter.props.Door)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)

local FUNC_TRAVERSE_FOLDERS = function(inst: Instance): boolean
	return inst:IsA("Folder")
end

local function traverse(
	root: Instance,
	traverseCondition: (Instance) -> boolean,
	callback: (Instance) -> ()
): ()
	local stack = {root}
	local index = 1

	while index > 0 do
		local current = stack[index]
		stack[index] = nil
		index = index - 1

		if current ~= root then
			callback(current)
		end

		if traverseCondition(current) then
			local children = current:GetChildren()
			for i = #children, 1, -1 do
				index = index + 1
				stack[index] = children[i]
			end
		end
	end
end

local function weld(part0: BasePart, part1: BasePart): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part1
	return weld
end

function startsWith(mainString: string, startString: string)
	return string.match(mainString, "^" .. string.gsub(startString, "([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")) ~= nil
end

--

local ROOT = (workspace :: any).Level or (workspace :: any).DebugMission
local PROPS_FOLDER = ROOT.Props :: Folder

local DEBUG_DIR = false
local DEBUG_SIDES_TRIGGER = true
local RED = Color3.new(1, 0, 0)
local BLUE = Color3.new(0, 0, 1)
local PROMPT_ACTIVATION_DIST = 5

local doors: { [Door.Door]: true } = {}

task.wait(2)

traverse(PROPS_FOLDER, FUNC_TRAVERSE_FOLDERS, function(inst)
	if not inst:IsA("Model") or not startsWith(inst.Name, "DoorMetal") then
		return
	end

	local base = inst:FindFirstChild("Base")
	if base and base:IsA("BasePart") then
		print(inst)
		local baseCFrame = base.CFrame
		local basePos = baseCFrame.Position
		local lookVec = baseCFrame.LookVector
		local positiveLookVec = lookVec
		local negativeLookVec = -lookVec

		local part0 = inst:FindFirstChild("Part0") :: BasePart
		local handle = inst:FindFirstChild("Handle") :: BasePart

		local doorSizeZ = part0.Size.Z
		local doorSizeX = part0.Size.X

		local soundOpen = ReplicatedStorage.shared.assets.sounds.props.door_generic_open:Clone()
		local soundClose = ReplicatedStorage.shared.assets.sounds.props.door_generic_close_2:Clone()
		local soundUnlock = ReplicatedStorage.shared.assets.sounds.gear_shift:Clone()

		soundOpen.Parent = base
		soundClose.Parent = base
		soundUnlock.Parent = base

		if DEBUG_DIR then
			Draw.direction(basePos, positiveLookVec, BLUE)
			Draw.direction(basePos, negativeLookVec, RED)
		end

		-- Setup

		local attatchmentAddDist = 0.3

		local frontAttatchment = Instance.new("Attachment")
		frontAttatchment.Name = "Front"
		frontAttatchment.Position = Vector3.new(0, 0, (-doorSizeZ / 2) + -attatchmentAddDist)
		frontAttatchment.Parent = part0

		local frontProxPrompt = Instance.new("ProximityPrompt")
		frontProxPrompt.Style = Enum.ProximityPromptStyle.Custom
		frontProxPrompt.MaxActivationDistance = PROMPT_ACTIVATION_DIST
		frontProxPrompt.Parent = frontAttatchment
	
		local backAttatchment = Instance.new("Attachment")
		backAttatchment.Name = "Back"
		backAttatchment.Position = Vector3.new(0, 0, (doorSizeZ / 2) + attatchmentAddDist)
		backAttatchment.Orientation = Vector3.new(0, 180, 0)
		backAttatchment.Parent = part0

		local backProxPrompt = Instance.new("ProximityPrompt")
		backProxPrompt.Style = Enum.ProximityPromptStyle.Custom
		backProxPrompt.MaxActivationDistance = PROMPT_ACTIVATION_DIST
		backProxPrompt.Parent = backAttatchment

		local middleAttatchment = Instance.new("Attachment")
		middleAttatchment:SetAttribute("OmniDir", true)
		middleAttatchment.Parent = base

		local middleProxPrompt = Instance.new("ProximityPrompt")
		middleProxPrompt.Style = Enum.ProximityPromptStyle.Custom
		middleProxPrompt.MaxActivationDistance = PROMPT_ACTIVATION_DIST + (frontAttatchment.WorldPosition - backAttatchment.WorldPosition).Magnitude / 2 
		middleProxPrompt.Parent = middleAttatchment

		local hingeAttatchment = Instance.new("Attachment")
		hingeAttatchment.Name = "Hinge"
		hingeAttatchment.Position = Vector3.new(doorSizeX / 2, 0, 0)
		hingeAttatchment.Parent = base

		local hingePart = Instance.new("Part")
		hingePart.Name = "HingePart"
		hingePart.Position = hingeAttatchment.WorldPosition
		hingePart.Size = Vector3.one
		hingePart.Transparency = 1
		hingePart.CanCollide = false
		hingePart.CanQuery = false
		hingePart.AudioCanCollide = false
		hingePart.Anchored = true
		hingePart.Parent = inst

		-- TODO: This is too hardcoded on Part0 and Handle

		base.CanCollide = false
		base.CanQuery = false

		part0.Anchored = false
		handle.Anchored = false

		weld(part0, hingePart)
		weld(handle, hingePart)

		-- Setup

		local lockFront = base:GetAttribute("LockFront") :: boolean?
		local lockBack = base:GetAttribute("LockBack") :: boolean?
		local autoLock = base:GetAttribute("AutoLock") :: boolean?
		local remoteUnlock = base:GetAttribute("RemoteUnlock") :: string?

		local newDoor = Door.new(
			hingePart, {
				front = frontProxPrompt,
				back = backProxPrompt,
				middle = middleProxPrompt
			}, PROMPT_ACTIVATION_DIST,
			{
				handle,
				part0
			},
			lockFront,
			lockBack,
			autoLock,
			remoteUnlock
		)
		doors[newDoor] = true

		-- Connections

		frontProxPrompt.Triggered:Connect(function(player)
			if DEBUG_SIDES_TRIGGER then
				print("Proximity prompt", "Front", "triggered for", inst)
			end
			newDoor:onPromptTriggered(Door.Sides.FRONT)
			if newDoor.state == Door.States.OPENING then
				soundOpen:Play()
			else
				soundClose:Play()
			end
		end)

		backProxPrompt.Triggered:Connect(function(player)
			if DEBUG_SIDES_TRIGGER then
				print("Proximity prompt", "Back", "triggered for", inst)
			end
			newDoor:onPromptTriggered(Door.Sides.BACK)
			if newDoor.state == Door.States.OPENING then
				soundOpen:Play()
			else
				soundClose:Play()
			end
		end)

		middleProxPrompt.Triggered:Connect(function(player)
			if DEBUG_SIDES_TRIGGER then
				print("Proximity prompt", "Middle", "triggered for", inst)
			end
			newDoor:onPromptTriggered(Door.Sides.MIDDLE)
			if newDoor.state == Door.States.OPENING then
				soundOpen:Play()
			else
				soundClose:Play()
			end
		end)

		if remoteUnlock then
			if not GlobalStatesHolder.hasState(remoteUnlock) then
				GlobalStatesHolder.setState(remoteUnlock, false)
			end
			GlobalStatesHolder.getStateChangedConnection(remoteUnlock):Connect(function(v)
				if v then
					newDoor:unlockBothSides()
					soundUnlock:Play()
				end
			end)
		end
	end
end)

RunService.PostSimulation:Connect(function(deltaTime)
	for doorObj in doors do
		doorObj:update(deltaTime)
	end
end)
