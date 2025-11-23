--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Door = require(ServerScriptService.server.world.level.clutter.props.Door)
local DoorHingeComponent = require(ServerScriptService.server.world.level.clutter.props.DoorHingeComponent)
local DoorPromptComponent = require(ServerScriptService.server.world.level.clutter.props.DoorPromptComponent)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

local DEBUG_INST_INIT = false
local DEBUG_DIR = false
local DEBUG_SIDES_TRIGGER = false
local RED = Color3.new(1, 0, 0)
local BLUE = Color3.new(0, 0, 1)
local PROMPT_ACTIVATION_DIST = 5
local RESERVED_DOOR_PARTS_NAMES = {
	["Part0"] = true,
	["Base"] = true
}

local DoorCreator = {}

local function weld(part0: BasePart, part1: BasePart): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part1
	return weld
end

function DoorCreator.createFromPlaceholder(placeholder: BasePart, model: Model): Door.Door
	if DEBUG_INST_INIT then
		print(model)
	end
	local base = model:FindFirstChild("Base") :: BasePart
	local baseCFrame = base.CFrame
	local basePos = baseCFrame.Position
	local lookVec = baseCFrame.LookVector
	local positiveLookVec = lookVec
	local negativeLookVec = -lookVec

	local isDoubleDoor = base:GetAttribute("DoubleDoor") :: boolean?

	local part0 = model:FindFirstChild("Part0") :: BasePart
	local nonMainDoorParts: {BasePart} = {}

	for _, part in model:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end

		if RESERVED_DOOR_PARTS_NAMES[part.Name] then
			continue
		end

		table.insert(nonMainDoorParts, part)
	end

	local doorSizeZ = part0.Size.Z

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
	local doorParts = {}

	local baseSizeX = base.Size.X
	local hingeAttatchment = Instance.new("Attachment")
	hingeAttatchment.Name = "Hinge"
	hingeAttatchment.Position = Vector3.new(baseSizeX / 2, 0, 0)
	hingeAttatchment.Parent = base
	local secondHingeAttatchment

	if isDoubleDoor then
		secondHingeAttatchment = Instance.new("Attachment")
		secondHingeAttatchment.Name = "Hinge"
		secondHingeAttatchment.Position = Vector3.new(-(baseSizeX / 2), 0, 0)
		secondHingeAttatchment.Parent = base
	end

	local hingePart = Instance.new("Part")
	hingePart.Name = "HingePart"
	hingePart.Position = hingeAttatchment.WorldPosition
	hingePart.Size = Vector3.one
	hingePart.Transparency = 1
	hingePart.CanCollide = false
	hingePart.CanQuery = false
	hingePart.AudioCanCollide = false
	hingePart.Anchored = true
	hingePart.Parent = model

	local hingePart2
	if isDoubleDoor and secondHingeAttatchment then
		hingePart2 = Instance.new("Part")
		hingePart2.Name = "HingePart"
		hingePart2.Position = secondHingeAttatchment.WorldPosition
		hingePart2.Size = Vector3.one
		hingePart2.Transparency = 1
		hingePart2.CanCollide = false
		hingePart2.CanQuery = false
		hingePart2.AudioCanCollide = false
		hingePart2.Anchored = true
		hingePart2.Parent = model
	end

	-- TODO: This is too hardcoded on Part0 and Handle

	base.CanCollide = false
	base.CanQuery = false

	part0.Anchored = false
	for _, part in nonMainDoorParts do
		part.Anchored = false
	end

	table.insert(doorParts, part0)
	for _, part in nonMainDoorParts do
		table.insert(doorParts, part)
	end
	
	local part0_OrigCF = part0.CFrame
	local nonDoorParts_OrigCF = {} :: { [BasePart]: CFrame }
	for _, part in nonMainDoorParts do
		nonDoorParts_OrigCF[part] = part.CFrame
	end
	local prompts = {} :: DoorPromptComponent.SingleDoorPrompts | DoorPromptComponent.DoubleDoorPrompts
	local attatchmentAddDist = 0.3

	if isDoubleDoor and hingePart2 then
		local part1 = part0:Clone()
		part1.Name = "Part1"
		part1.Parent = model

		-- Istg all of these for loops are unoptimized as shit
		local nonDoorPartsClones: { [BasePart]: BasePart } = {} -- k: original; v: clone
		for _, part in nonMainDoorParts do
			local clone = part:Clone()
			clone.Parent = part.Parent
			table.insert(doorParts, clone)
			nonDoorPartsClones[part] = clone
		end

		table.insert(doorParts, part1)

		local quarterBaseSizeX = base.Size.X / 4
		local rotation180 = CFrame.Angles(0, math.rad(180), 0)
		
		local leftDoorOffset = CFrame.new(quarterBaseSizeX, 0, 0)
		
		local rightDoorOffset = CFrame.new(-quarterBaseSizeX, 0, 0)

		-- 2. Get the door part's CFrame *relative to the door panel*
		local nonDoorPartsRelativeCF: { [BasePart]: CFrame } = {}
		for _, part in nonMainDoorParts do
			nonDoorPartsRelativeCF[part] = part0_OrigCF:ToObjectSpace(nonDoorParts_OrigCF[part])
		end

		-- 3. Position the LEFT door (part0 and handle)
		local leftDoorCF = base.CFrame * leftDoorOffset
		part0.CFrame = leftDoorCF
		for _, part in nonMainDoorParts do
			part.CFrame = leftDoorCF * nonDoorPartsRelativeCF[part]
		end

		-- 4. Position the RIGHT door (part1 and handle1)
		-- This CFrame correctly positions and rotates the door panel.
		local rightDoorCF = base.CFrame * rightDoorOffset * rotation180
		part1.CFrame = rightDoorCF

		-- 5. Create the mirrored CFrame for the RIGHT handle (handle1)
		
		for orig, clone in nonDoorPartsClones do
			-- Get the handle's original relative position and rotation
			local relCF = nonDoorPartsRelativeCF[orig]
			local relPos = relCF.Position
			local rx, ry, rz = relCF:ToOrientation()

			-- We use the SAME relative position (relPos.X, not -relPos.X).
			-- We mirror the rotation of the handle by negating the
			-- Y-axis (yaw) and Z-axis (roll) rotation.
			local mirroredHandleRelativeCF = CFrame.new(relPos.X, relPos.Y, relPos.Z) * CFrame.Angles(rx, -ry, -rz)
			
			clone.CFrame = rightDoorCF * mirroredHandleRelativeCF
			weld(clone, hingePart2)
		end

		weld(part1, hingePart2)
		-- Attatchments

		----

		local frontAttatchment1 = Instance.new("Attachment")
		frontAttatchment1.Name = "Front"
		frontAttatchment1.Position = Vector3.new(0, 0, (-doorSizeZ / 2) + -attatchmentAddDist)
		frontAttatchment1.Parent = part1

		local frontProxPrompt1 = Instance.new("ProximityPrompt")
		frontProxPrompt1.Style = Enum.ProximityPromptStyle.Custom
		frontProxPrompt1.MaxActivationDistance = PROMPT_ACTIVATION_DIST
		frontProxPrompt1.Parent = frontAttatchment1
	
		local backAttatchment1 = Instance.new("Attachment")
		backAttatchment1.Name = "Back"
		backAttatchment1.Position = Vector3.new(0, 0, (doorSizeZ / 2) + attatchmentAddDist)
		backAttatchment1.Orientation = Vector3.new(0, 180, 0)
		backAttatchment1.Parent = part1

		local backProxPrompt1 = Instance.new("ProximityPrompt")
		backProxPrompt1.Style = Enum.ProximityPromptStyle.Custom
		backProxPrompt1.MaxActivationDistance = PROMPT_ACTIVATION_DIST
		backProxPrompt1.Parent = backAttatchment1

		----

		local frontAttatchment2 = Instance.new("Attachment")
		frontAttatchment2.Name = "Front"
		frontAttatchment2.Position = Vector3.new(0, 0, (-doorSizeZ / 2) + -attatchmentAddDist)
		frontAttatchment2.Parent = part0

		local frontProxPrompt2 = Instance.new("ProximityPrompt")
		frontProxPrompt2.Style = Enum.ProximityPromptStyle.Custom
		frontProxPrompt2.MaxActivationDistance = PROMPT_ACTIVATION_DIST
		frontProxPrompt2.Parent = frontAttatchment2
	
		local backAttatchment2 = Instance.new("Attachment")
		backAttatchment2.Name = "Back"
		backAttatchment2.Position = Vector3.new(0, 0, (doorSizeZ / 2) + attatchmentAddDist)
		backAttatchment2.Orientation = Vector3.new(0, 180, 0)
		backAttatchment2.Parent = part0

		local backProxPrompt2 = Instance.new("ProximityPrompt")
		backProxPrompt2.Style = Enum.ProximityPromptStyle.Custom
		backProxPrompt2.MaxActivationDistance = PROMPT_ACTIVATION_DIST
		backProxPrompt2.Parent = backAttatchment2

		--

		local doubleDoorPrompts = prompts :: DoorPromptComponent.DoubleDoorPrompts
		doubleDoorPrompts.doorRightBack = {frontProxPrompt1} -- flipped because, well, we flipped the cloned door side.
		doubleDoorPrompts.doorRightFront = {backProxPrompt1}
		doubleDoorPrompts.doorLeftBack = {backProxPrompt2}
		doubleDoorPrompts.doorLeftFront = {frontProxPrompt2}
	end

	weld(part0, hingePart)
	for _, part in nonMainDoorParts do
		weld(part, hingePart)
	end

	-- Attatchments
	local frontAttatchment = Instance.new("Attachment")
	frontAttatchment.Name = "Front"
	frontAttatchment.Position = isDoubleDoor and Vector3.new(0, 0, (-base.Size.Z / 2) + -attatchmentAddDist) or Vector3.new(0, 0, (-doorSizeZ / 2) + -attatchmentAddDist)
	frontAttatchment.Parent = isDoubleDoor and base or part0

	local frontProxPrompt = Instance.new("ProximityPrompt")
	frontProxPrompt.Style = Enum.ProximityPromptStyle.Custom
	frontProxPrompt.MaxActivationDistance = PROMPT_ACTIVATION_DIST
	frontProxPrompt.Parent = frontAttatchment

	local backAttatchment = Instance.new("Attachment")
	backAttatchment.Name = "Back"
	backAttatchment.Position = isDoubleDoor and Vector3.new(0, 0, (base.Size.Z / 2) + attatchmentAddDist) or Vector3.new(0, 0, (doorSizeZ / 2) + attatchmentAddDist)
	backAttatchment.Orientation = Vector3.new(0, 180, 0)
	backAttatchment.Parent = isDoubleDoor and base or part0

	local backProxPrompt = Instance.new("ProximityPrompt")
	backProxPrompt.Style = Enum.ProximityPromptStyle.Custom
	backProxPrompt.MaxActivationDistance = PROMPT_ACTIVATION_DIST
	backProxPrompt.Parent = backAttatchment

	local middleAttatchment = Instance.new("Attachment")
	middleAttatchment.Name = "Middle"
	middleAttatchment:SetAttribute("OmniDir", true)
	middleAttatchment.Parent = base

	local middleProxPrompt = Instance.new("ProximityPrompt")
	middleProxPrompt.Style = Enum.ProximityPromptStyle.Custom
	middleProxPrompt.MaxActivationDistance = PROMPT_ACTIVATION_DIST + (frontAttatchment.WorldPosition - backAttatchment.WorldPosition).Magnitude / 2 
	middleProxPrompt.Parent = middleAttatchment

	if isDoubleDoor then
		local promptsForDouble = prompts :: DoorPromptComponent.DoubleDoorPrompts
		promptsForDouble.opening = {frontProxPrompt}
		promptsForDouble.closing = {backProxPrompt}
		promptsForDouble.middle = {middleProxPrompt}
	else
		local promptsForSingle = prompts :: DoorPromptComponent.SingleDoorPrompts
		promptsForSingle.back = {backProxPrompt}
		promptsForSingle.front = {frontProxPrompt}
		promptsForSingle.middle = {middleProxPrompt}
	end

	-- Setup

	local lockFront = base:GetAttribute("LockFront") :: boolean?
	local lockBack = base:GetAttribute("LockBack") :: boolean?
	local autoLock = base:GetAttribute("AutoLock") :: boolean?
	local remoteUnlock = base:GetAttribute("RemoteUnlock") :: string?

	local newDoor = Door.new(
		hingePart, {
			front = {frontProxPrompt},
			back = {backProxPrompt},
			middle = {middleProxPrompt}
		},
		DoorPromptComponent.new(prompts, isDoubleDoor or false),
		(isDoubleDoor and hingePart2) and DoorHingeComponent.double(hingePart, hingePart2) or DoorHingeComponent.single(hingePart),
		doorParts,
		lockFront,
		lockBack,
		autoLock,
		remoteUnlock
	)

	-- Connections

	local function triggerFront(player: Player): ()
		if DEBUG_SIDES_TRIGGER then
			print("Proximity prompt", "Front", "triggered for", model)
		end
		newDoor:onPromptTriggered(Door.Sides.FRONT)
		if newDoor.state == Door.States.OPENING then
			soundOpen:Play()
		else
			soundClose:Play()
		end
	end

	local function triggerBack(player: Player): ()
		if DEBUG_SIDES_TRIGGER then
			print("Proximity prompt", "Back", "triggered for", model)
		end
		newDoor:onPromptTriggered(Door.Sides.BACK)
		if newDoor.state == Door.States.OPENING then
			soundOpen:Play()
		else
			soundClose:Play()
		end
	end

	local function trigegrMiddle(player): ()
		if DEBUG_SIDES_TRIGGER then
			print("Proximity prompt", "Middle", "triggered for", model)
		end
		newDoor:onPromptTriggered(Door.Sides.MIDDLE)
		if newDoor.state == Door.States.OPENING then
			soundOpen:Play()
		else
			soundClose:Play()
		end
	end

	frontProxPrompt.Triggered:Connect(triggerFront)
	backProxPrompt.Triggered:Connect(triggerBack)
	middleProxPrompt.Triggered:Connect(trigegrMiddle)

	if isDoubleDoor then
		local promptsForDouble = prompts :: DoorPromptComponent.DoubleDoorPrompts
		promptsForDouble.doorLeftBack[1].Triggered:Connect(triggerBack)
		promptsForDouble.doorLeftFront[1].Triggered:Connect(triggerFront)
		promptsForDouble.doorRightBack[1].Triggered:Connect(triggerBack)
		promptsForDouble.doorRightFront[1].Triggered:Connect(triggerFront)
	end

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

	return newDoor
end

return DoorCreator