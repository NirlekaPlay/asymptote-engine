--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionTags = require(ServerScriptService.server.collection.CollectionTags)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Maid = require(ReplicatedStorage.shared.util.misc.Maid)
local InteractionPromptBuilder = require(ReplicatedStorage.shared.world.interaction.InteractionPromptBuilder)
local WorldInteractionPrompt = require(ReplicatedStorage.shared.world.interaction.WorldInteractionPrompt)
local Door = require(ServerScriptService.server.world.level.clutter.props.Door)
local DoorHingeComponent = require(ServerScriptService.server.world.level.clutter.props.DoorHingeComponent)
local DoorPromptComponent = require(ServerScriptService.server.world.level.clutter.props.DoorPromptComponent)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

local DEBUG_INST_INIT = false
local DEBUG_DIR = false
local DEBUG_SIDES_TRIGGER = false
local DEBUG_PATH_MOD_BOX = false
local DEBUG_PERPENDICULAR_MOD_BOX = false
local RED = Color3.new(1, 0, 0)
local BLUE = Color3.new(0, 0, 1)
local PROMPT_ACTIVATION_DIST = 5

local promptTemplate= InteractionPromptBuilder.new()
	:withPrimaryInteractionKey()
	:withActivationDistance(PROMPT_ACTIVATION_DIST)
	:withHoldDuration(0)
	:withOmniDir(false)
	:withTitleKey("ui.prompt.open")

local DoorCreator = {}

local function createPerpendicularParts(basePart: BasePart, sideWidth: number, sideHeight: number, sideThickness: number): {BasePart}
	-- -1 for left side, 1 for right side
	local directions = {-1, 1}
	local parts: {BasePart} = {}

	for _, dir in directions do
		local sidePart = Instance.new("Part")
		sidePart.Name = "SideCap"
		sidePart.Size = Vector3.new(sideThickness, sideHeight, sideWidth)
		sidePart.Transparency = 1
		sidePart.Anchored = true
		sidePart.Parent = workspace

		local xOffset = (basePart.Size.X / 2 + sideThickness / 2) * dir

		sidePart.CFrame = basePart.CFrame * CFrame.new(xOffset, 0, 0)
		table.insert(parts, sidePart)
	end

	return parts
end

local function createUprightAttachment(parentPart: BasePart, localPosition: Vector3, lookDirection: Vector3): Attachment
	local att = Instance.new("Attachment")
	
	-- Get the World Position where we want the attachment
	local worldPos = parentPart.CFrame:PointToWorldSpace(localPosition)
	
	-- Determine where looking "forward" or "backward" is in the real world
	local worldLookDir = parentPart.CFrame:VectorToWorldSpace(lookDirection)
	local lookAtTarget = worldPos + worldLookDir

	-- Create a World CFrame that is FORCED to be upright using Vector3.new(0, 1, 0)
	-- This ignores the Part's Z-axis/Roll and forces the attachment to be upright in the world
	local targetWorldCFrame = CFrame.lookAt(worldPos, lookAtTarget, Vector3.new(0, 1, 0))

	-- Convert this perfect World CFrame into a local CFrame relative to the Parent Part
	-- This mathematically calculates the exact offset/rotation needed to fix the tilt
	att.CFrame = parentPart.CFrame:ToObjectSpace(targetWorldCFrame)
	
	att.Parent = parentPart
	return att
end

local function weld(part0: BasePart, part1: BasePart): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part1
	return weld
end

function DoorCreator.createFromPlaceholder(placeholder: BasePart, model: Model, serverLevel: ServerLevel.ServerLevel): Door.Door
	if DEBUG_INST_INIT then
		print(model)
	end

	local maid = Maid.new()

	local context = serverLevel:getExpressionContext()

	local base = model:FindFirstChild("Base") :: BasePart
	local baseCFrame = base.CFrame
	local basePos = baseCFrame.Position
	local lookVec = baseCFrame.LookVector
	local positiveLookVec = lookVec
	local negativeLookVec = -lookVec

	local isDoubleDoor = base:GetAttribute("DoubleDoor") :: boolean?

	local part0 = if placeholder.Name == "DoorGlassFramed" then model:FindFirstChild("Part1") :: BasePart else model:FindFirstChild("Part0") :: BasePart
	local nonMainDoorParts: {BasePart} = {}

	local pathReqPart = Instance.new("Part")
	pathReqPart.Name = "DoorBounds"
	pathReqPart.CanCollide = false
	pathReqPart.AudioCanCollide = false
	pathReqPart.Anchored = true
	pathReqPart.Transparency = 1
	pathReqPart.CFrame = base.CFrame
	-- Why -1?
	-- It all started here: https://discord.com/channels/1023187658370990131/1090992851011252314/1461748604124401960
	pathReqPart.Size = Vector3.new(base.Size.X - 1, base.Size.Y - 1, base.Size.Z + 4)
	pathReqPart.CollisionGroup = CollisionGroupTypes.PATHFINDING_PART
	pathReqPart:AddTag(CollectionTags.DOOR_PATH_BOUNDS)
	pathReqPart.Parent = workspace

	local pathMod = Instance.new("PathfindingModifier")
	pathMod.Label = "Door"
	pathMod.PassThrough = true
	pathMod.Parent = pathReqPart

	maid:giveTask(pathReqPart)

	local edgeParts = createPerpendicularParts(base, 10, base.Size.Y, 1)
	for _, part in edgeParts do
		part.Name = "DoorPerpendicularPart"
		part.CanCollide = false
		part.AudioCanCollide = false
		part.Anchored = true
		part.Transparency = 1
		part.CollisionGroup = CollisionGroupTypes.PATHFINDING_PART
		part.Parent = base

		if DEBUG_PERPENDICULAR_MOD_BOX then
			Draw.box(part, part.Size)
		end

		local pathMod1 = Instance.new("PathfindingModifier")
		pathMod1.Label = "DoorPerpendicularPart"
		pathMod1.PassThrough = true
		pathMod1.Parent = part
	end

	if DEBUG_PATH_MOD_BOX then
		Draw.box(pathReqPart, pathReqPart.Size)
	end

	for _, part in model:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end

		if part == base or part == part0 then
			continue
		end

		local newPathMod = Instance.new("PathfindingModifier")
		newPathMod.Label = "Door"
		newPathMod.PassThrough = true
		newPathMod.Parent = part

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

		local nonDoorPartsClones: { [BasePart]: BasePart } = {}
		for _, part in nonMainDoorParts do
			local clone = part:Clone()
			clone.Parent = part.Parent
			table.insert(doorParts, clone)
			nonDoorPartsClones[part] = clone
		end

		table.insert(doorParts, part1)

		-- We actually mirror this one now.
		local baseCF = base.CFrame
		local halfWidth = base.Size.X / 4

		-- Position LEFT Door (Part0)
		-- Offset to the Left (-X in local space if base is centered)
		-- Note: Ensure halfWidth polarity matches your setup. Usually Left is +X or -X depending on Base LookVector.
		-- Assuming Standard Roblox: Left is +X relative to looking forward? No, Left is -X. 
		-- Adjust the sign of 'halfWidth' below if your doors swap sides.
		local leftOffsetCF = baseCF * CFrame.new(halfWidth, 0, 0) 
		local part0RelToBase = baseCF:ToObjectSpace(part0_OrigCF)
		part0.CFrame = leftOffsetCF * part0RelToBase

		-- Position non-door parts for Left Door
		for _, part in nonMainDoorParts do
			local rel = part0_OrigCF:ToObjectSpace(nonDoorParts_OrigCF[part])
			part.CFrame = part0.CFrame * rel
		end

		-- Position RIGHT Door (Part1) - MIRRORING LOGIC
		-- We want Part1 at the opposite side (-halfWidth)
		local rightOffsetCF = baseCF * CFrame.new(-halfWidth, 0, 0)
		
		-- We rotate the door 180 on Y to put the hinge on the outside
		-- But we acknowledge this makes the door face "Backwards" in Local Space
		local part1Rotation = part0RelToBase.Rotation * CFrame.Angles(0, math.pi, 0)
		
		-- Apply calculation
		part1.CFrame = rightOffsetCF * part1Rotation * CFrame.new(part0RelToBase.Position)

		-- Position Cloned Handles (Non-Door Parts) - CORRECTION
		for orig, clone in nonDoorPartsClones do
			-- Get handle position relative to the base
			local relToBase = baseCF:ToObjectSpace(orig.CFrame)
			
			-- Flip the X position to move it to the other side of the door set
			local mirroredPos = Vector3.new(-relToBase.X, relToBase.Y, relToBase.Z)
			
			-- To mirror the rotation properly for a handle at 90 degrees:
			-- we take the original rotation and add a 180-degree turn around the Y-axis
			-- then we invert the Z-axis rotation to account for the flip
			local rx, ry, rz = relToBase:ToEulerAnglesYXZ()
			local mirroredRot = CFrame.fromEulerAnglesYXZ(rx, -ry + math.pi, -rz)
			
			clone.CFrame = baseCF * CFrame.new(mirroredPos) * mirroredRot
			
			weld(clone, part1)
		end

		weld(part0, hingePart)
		weld(part1, hingePart2)

		local attatchmentOffset = doorSizeZ / 2 + attatchmentAddDist

		-- RIGHT door attachments (part1)
		-- Front: Position is -offset, Look Direction is Forward (0, 0, -1)
		local frontAttatchment1 = createUprightAttachment(part1, Vector3.new(0, 0, -attatchmentOffset), Vector3.new(0, 0, -1))
		frontAttatchment1.Name = "Front"

		local frontProxPrompt1 = promptTemplate:create(part1, context, frontAttatchment1)

		-- Back: Position is +offset, Look Direction is Backward (0, 0, 1)
		local backAttatchment1 = createUprightAttachment(part1, Vector3.new(0, 0, attatchmentOffset), Vector3.new(0, 0, 1))
		backAttatchment1.Name = "Back"

		local backProxPrompt1 = promptTemplate:create(part1, context, backAttatchment1)

		-- LEFT door attachments (part0)
		-- Front
		local frontAttatchment2 = createUprightAttachment(part0, Vector3.new(0, 0, -attatchmentOffset), Vector3.new(0, 0, -1))
		frontAttatchment2.Name = "Front"

		local frontProxPrompt2 = promptTemplate:create(part0, context, frontAttatchment2)

		-- Back
		local backAttatchment2 = createUprightAttachment(part0, Vector3.new(0, 0, attatchmentOffset), Vector3.new(0, 0, 1))
		backAttatchment2.Name = "Back"

		local backProxPrompt2 = promptTemplate:create(part0, context, backAttatchment2)

		local doubleDoorPrompts = prompts :: DoorPromptComponent.DoubleDoorPrompts
		doubleDoorPrompts.doorRightBack = {frontProxPrompt1}
		doubleDoorPrompts.doorRightFront = {backProxPrompt1}
		doubleDoorPrompts.doorLeftBack = {backProxPrompt2}
		doubleDoorPrompts.doorLeftFront = {frontProxPrompt2}
	end

	weld(part0, hingePart)
	for _, part in nonMainDoorParts do
		weld(part, hingePart)
	end

	local lockFront = base:GetAttribute("LockFront") :: boolean?
	local lockBack = base:GetAttribute("LockBack") :: boolean?
	local autoLock = base:GetAttribute("AutoLock") :: boolean?
	local remoteUnlock = base:GetAttribute("RemoteUnlock") :: string?

	-- Attatchments
	local zOffset = isDoubleDoor and (base.Size.Z / 2 + attatchmentAddDist) or (doorSizeZ / 2 + attatchmentAddDist)
	local attachmentParent = isDoubleDoor and base or part0

	local frontAttatchment = createUprightAttachment(
		attachmentParent,
		Vector3.new(0, 0, -zOffset),
		Vector3.new(0, 0, -1)
	)
	frontAttatchment.Name = "Front"

	local backAttatchment = createUprightAttachment(
		attachmentParent,
		Vector3.new(0, 0, zOffset),
		Vector3.new(0, 0, 1)
	)
	backAttatchment.Name = "Back"

	--[[local frontAttatchment = Instance.new("Attachment")
	frontAttatchment.Name = "Front"
	frontAttatchment.Position = isDoubleDoor and Vector3.new(0, 0, (-base.Size.Z / 2) + -attatchmentAddDist) or Vector3.new(0, 0, (-doorSizeZ / 2) + -attatchmentAddDist)
	frontAttatchment.Parent = isDoubleDoor and base or part0]]

	local validRemoteUnlock = remoteUnlock and remoteUnlock ~= ""

	local frontProxPrompt
	if lockFront and validRemoteUnlock then
		frontProxPrompt = promptTemplate:fork()
			:withDisabledSubtitleExpr(`'ui.prompt.locked'`)
			:withServerEnabledExpression(`{remoteUnlock}`)
			:create(attachmentParent, context, frontAttatchment)
	elseif lockFront and not validRemoteUnlock then
		frontProxPrompt = promptTemplate:fork()
			:withDisabledSubtitleExpr(`'ui.prompt.locked'`)
			:withServerEnabledExpression(`false`)
			:create(attachmentParent, context, frontAttatchment)
	else
		frontProxPrompt = promptTemplate:fork()
			:withDisabledSubtitleExpr(`'ui.prompt.locked'`)
			:create(attachmentParent, context, frontAttatchment)
	end

	--[[local backAttatchment = Instance.new("Attachment")
	backAttatchment.Name = "Back"
	backAttatchment.Position = isDoubleDoor and Vector3.new(0, 0, (base.Size.Z / 2) + attatchmentAddDist) or Vector3.new(0, 0, (doorSizeZ / 2) + attatchmentAddDist)
	backAttatchment.Orientation = Vector3.new(0, 180, 0)
	backAttatchment.Parent = isDoubleDoor and base or part0]]

	local backProxPrompt
	if lockBack and validRemoteUnlock then
		backProxPrompt = promptTemplate:fork()
			:withDisabledSubtitleExpr(`'ui.prompt.locked'`)
			:withServerEnabledExpression(`{remoteUnlock}`)
			:create(attachmentParent, context, backAttatchment)
	elseif lockBack and not validRemoteUnlock then
		backProxPrompt = promptTemplate:fork()
			:withDisabledSubtitleExpr(`'ui.prompt.locked'`)
			:withServerEnabledExpression(`false`)
			:create(attachmentParent, context, backAttatchment)
	else
		backProxPrompt = promptTemplate:fork()
			:withDisabledSubtitleExpr(`'ui.prompt.locked'`)
			:create(attachmentParent, context, backAttatchment)
	end

	local middleAttatchment = Instance.new("Attachment")
	middleAttatchment.Name = "Middle"
	middleAttatchment.Parent = base

	local middleProxPrompt = promptTemplate:fork()
		:withOmniDir(true)
		:withActivationDistance(PROMPT_ACTIVATION_DIST + (frontAttatchment.WorldPosition - backAttatchment.WorldPosition).Magnitude / 2 )
		:create(attachmentParent, context, middleAttatchment)

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

	for name, prompts1 in prompts do
		for _, prompt in prompts1 :: { WorldInteractionPrompt.WorldInteractionPrompt } do
			maid:giveTask(prompt)
		end
	end

	local newDoor = Door.new(
		hingePart, {
			front = {frontProxPrompt},
			back = {backProxPrompt},
			middle = {middleProxPrompt}
		},
		DoorPromptComponent.new(prompts, isDoubleDoor or false),
		(isDoubleDoor and hingePart2) and DoorHingeComponent.double(hingePart, hingePart2) or DoorHingeComponent.single(hingePart),
		pathReqPart,
		lookVec,
		maid,
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

	local function triggerMiddle(player): ()
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

	maid:giveTask(frontProxPrompt:getTriggeredEvent():Connect(triggerFront))
	maid:giveTask(backProxPrompt:getTriggeredEvent():Connect(triggerBack))
	maid:giveTask(middleProxPrompt:getTriggeredEvent():Connect(triggerMiddle))

	if isDoubleDoor then
		local promptsForDouble = prompts :: DoorPromptComponent.DoubleDoorPrompts
		maid:giveTask(promptsForDouble.doorLeftBack[1]:getTriggeredEvent():Connect(triggerBack))
		maid:giveTask(promptsForDouble.doorLeftFront[1]:getTriggeredEvent():Connect(triggerFront))
		maid:giveTask(promptsForDouble.doorRightBack[1]:getTriggeredEvent():Connect(triggerBack))
		maid:giveTask(promptsForDouble.doorRightFront[1]:getTriggeredEvent():Connect(triggerFront))
	end

	if remoteUnlock and string.match(remoteUnlock, "%S") ~= nil then
		if not GlobalStatesHolder.hasState(remoteUnlock) then
			GlobalStatesHolder.setState(remoteUnlock, false)
		end
		maid:giveTask(GlobalStatesHolder.getStateChangedConnection(remoteUnlock):Connect(function(v)
			if v and not (newDoor:isOpen() or newDoor:isTurning()) then
				task.wait(0.3)
				if GlobalStatesHolder.getState(remoteUnlock) then
					newDoor:unlockBothSides()
					soundUnlock:Play()
				end
			end
		end))
	end

	return newDoor
end

return DoorCreator