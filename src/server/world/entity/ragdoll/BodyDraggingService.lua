--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local InteractionPromptBuilder = require(ReplicatedStorage.shared.world.interaction.InteractionPromptBuilder)
local WorldInteractionPrompt = require(ReplicatedStorage.shared.world.interaction.WorldInteractionPrompt)

type WorldInteractionPrompt = WorldInteractionPrompt.WorldInteractionPrompt
type ServerLevel = ServerLevel.ServerLevel 

--[=[
	@class BodyDraggingService
]=]
local BodyDraggingService = {}

local function pinHandToShoulder(ragdollHand: BasePart, playerShoulder: BasePart): ()
	local a0 = Instance.new("Attachment")
	a0.Name ..= "BodyDrag"
	a0.CFrame = CFrame.new(0, 0, 0)
	a0.Parent = ragdollHand

	local a1 = Instance.new("Attachment")
	a1.Name ..= "BodyDrag"
	a1.CFrame = CFrame.new(0, 0, 0)
	a1.Parent = playerShoulder

	local align = Instance.new("AlignPosition")
	align.Name = "BodyDragAlignPos"
	align.Mode = Enum.PositionAlignmentMode.TwoAttachment
	align.Attachment0 = a0
	align.Attachment1 = a1
	align.MaxForce = 5000      -- soft, not iron grip
	align.Responsiveness = 15  -- low = springy/loose, not teleporting
	align.Parent = ragdollHand
end

function BodyDraggingService.startDragging(char: Model, toPlayer: Player): ()
	if not char or not char:IsDescendantOf(workspace) then
		return
	end

	if not toPlayer or not toPlayer.Character or not toPlayer.Character:IsDescendantOf(workspace) then
		return
	end

	BodyDraggingService.ensureRagdoll(char)

	local playerCharacter = toPlayer.Character
	local charRoot = char:FindFirstChild("HumanoidRootPart") :: BasePart
	local playerRoot = playerCharacter:FindFirstChild("Torso") :: BasePart

	local charDragAttachment = Instance.new("Attachment")
	charDragAttachment.Name = "CarryAttachment_Ragdoll"
	charDragAttachment.CFrame = CFrame.new(0, 0, 0) 
	charDragAttachment.Parent = charRoot

	local playerCarryAttachment = Instance.new("Attachment")
	playerCarryAttachment.Name = "CarryAttachment_Player"
	playerCarryAttachment.CFrame = CFrame.new(0, 0.5, 1.2)
	playerCarryAttachment.Parent = playerRoot

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Name = "BodyDragAlignPos"
	alignPosition.Mode = Enum.PositionAlignmentMode.TwoAttachment
	alignPosition.Attachment0 = charDragAttachment
	alignPosition.Attachment1 = playerCarryAttachment
	alignPosition.MaxForce = math.huge -- "math.huge" prevents the body from sagging
	alignPosition.Responsiveness = 200 -- High responsiveness makes it feel attached
	alignPosition.Parent = charRoot

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "BodyDragAlignRot"
	alignOrientation.Mode = Enum.OrientationAlignmentMode.TwoAttachment
	alignOrientation.Attachment0 = charDragAttachment
	alignOrientation.Attachment1 = playerCarryAttachment
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Responsiveness = 200
	alignOrientation.Parent = charRoot

	for _, descendant in char:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant:SetNetworkOwner(toPlayer)
			descendant.CollisionGroup = CollisionGroupTypes.BODY_DRAG_RAGDOLL
		end
	end

	local ragdollLeftHand  = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
	local ragdollRightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	local playerLeftShoulder  = playerCharacter:FindFirstChild("LeftUpperArm") or playerCharacter:FindFirstChild("Left Arm")
	local playerRightShoulder = playerCharacter:FindFirstChild("RightUpperArm") or playerCharacter:FindFirstChild("Right Arm")

	pinHandToShoulder(ragdollLeftHand :: BasePart, playerLeftShoulder :: BasePart)
	pinHandToShoulder(ragdollRightHand :: BasePart, playerRightShoulder :: BasePart)

	local existingBodyDragObjectValue = toPlayer.Character:FindFirstChild("CurrentDraggingChar")
	if existingBodyDragObjectValue and existingBodyDragObjectValue:IsA("ObjectValue") then
		existingBodyDragObjectValue.Value = char
	else
		local currentlyDraggingCharacter = Instance.new("ObjectValue")
		currentlyDraggingCharacter.Name = "CurrentDraggingChar"
		currentlyDraggingCharacter.Value = char
		currentlyDraggingCharacter.Parent = toPlayer.Character
	end

	((toPlayer :: any).Character.Humanoid :: Humanoid).JumpPower = 0;
	((toPlayer :: any).Character.Humanoid :: Humanoid).JumpHeight = 0;
	((toPlayer :: any).Character.Humanoid :: Humanoid).WalkSpeed = 10;

	((toPlayer :: any).Character.Humanoid :: Humanoid):SetAttribute("CanSprint", false)
end

function BodyDraggingService.stopDragging(char: Model, toPlayer: Player): ()
	if not char or not char:IsDescendantOf(workspace) then
		return
	end

	for _, descendant in char:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name == "HumanoidRootPart" then
			local existingTriggerAttachment = descendant:FindFirstChild("BodyDragTrigger")
			if existingTriggerAttachment and existingTriggerAttachment:IsA("Attachment") then
				-- TODO: Let WorldInteractionPrompt handle this but ehhh
				(existingTriggerAttachment:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt).Enabled = true
				continue
			end
		end

		if descendant:IsA("Attachment") or descendant:IsA("AlignPosition") or descendant:IsA("AlignOrientation") then
			if string.find(descendant.Name, "BodyDrag") then
				if descendant:IsA("Attachment") and descendant.Name == "BodyDragTrigger" then
					continue
				end
				descendant:Destroy()
			end
		end
	end

	if toPlayer and toPlayer.Character then
		local playerRoot = toPlayer.Character:FindFirstChild("HumanoidRootPart")
		if playerRoot then
			for _, descendant in toPlayer.Character:GetDescendants() do
				if descendant:IsA("Attachment") and string.find(descendant.Name, "BodyDrag") then
					descendant:Destroy()
				end
			end
		end
	end

	for _, descendant in char:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant:SetNetworkOwner(nil)
			descendant.CollisionGroup = CollisionGroupTypes.RAGDOLL_COLLIDER_PART
			descendant.Massless = false
		end
	end

	((toPlayer :: any).Character.Humanoid :: Humanoid).JumpPower = 0;
	((toPlayer :: any).Character.Humanoid :: Humanoid).JumpHeight = 7.2;
	((toPlayer :: any).Character.Humanoid :: Humanoid).WalkSpeed = 16;
	((toPlayer :: any).Character.Humanoid :: Humanoid):SetAttribute("CanSprint", true)
end

function BodyDraggingService.createDragPromptOnPart(serverLevel: ServerLevel, part: BasePart): WorldInteractionPrompt
	local promptAttachment = Instance.new("Attachment")
	promptAttachment.Name = "BodyDragTrigger"
	promptAttachment.Parent = part

	local prompt = InteractionPromptBuilder.new()
		:withHoldDuration(2)
		:withActivationDistance(7)
		:withHoldStatus(`2`)
		:withPrimaryInteractionKey()
		:withTitleKey(`ui.prompt.carry`)
		:create(part, serverLevel:getExpressionContext(), promptAttachment)

	-- NOTES: Breaks encapsulation
	prompt.proxPrompt.RequiresLineOfSight = false

	return prompt
end

--

--[=[
	Ragdolls the given `character` if not already.
]=]
function BodyDraggingService.ensureRagdoll(character: Model): ()
	if character then
		local isRagdollBoolValue = character:FindFirstChild("IsRagdoll") :: BoolValue?
		if isRagdollBoolValue and isRagdollBoolValue.Value ~= true then
			isRagdollBoolValue.Value = true
		end
	end
end

--

function BodyDraggingService.onReceiveStopDragFromPlayer(player: Player): ()
	if not player.Character then
		return
	end

	local currentlyDraggingCharValue = player.Character:FindFirstChild("CurrentDraggingChar")
	if currentlyDraggingCharValue and currentlyDraggingCharValue:IsA("ObjectValue") then
		if not currentlyDraggingCharValue.Value then
			return
		end

		BodyDraggingService.stopDragging(currentlyDraggingCharValue.Value :: Model, player)
		currentlyDraggingCharValue.Value = nil
	end
end

TypedRemotes.ServerboundStopBodyDrag.OnServerEvent:Connect(BodyDraggingService.onReceiveStopDragFromPlayer)

return BodyDraggingService