--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local InteractionPromptBuilder = require(ReplicatedStorage.shared.world.interaction.InteractionPromptBuilder)
local WorldInteractionPrompt = require(ReplicatedStorage.shared.world.interaction.WorldInteractionPrompt)

local TAKEDOWN_ANIM_ID = 97587604203797
local MOVE_TIMEOUT = 1.5

local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://" .. TAKEDOWN_ANIM_ID

--[=[
	@class TakedownService
]=]
local TakedownService = {}

local tracked: { [Model]: { prompt: WorldInteractionPrompt.WorldInteractionPrompt, connection: RBXScriptConnection } } = {}

local function isPlayerBehind(targetRoot: BasePart, playerRoot: BasePart): boolean
	local dot = targetRoot.CFrame.LookVector:Dot((playerRoot.Position - targetRoot.Position).Unit)
	return math.deg(math.acos(dot)) > 80
end

local function doTakedown(npcCharacter: Model, prompt: ProximityPrompt, player: Player)
	local npcRoot = npcCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
	local npcHumanoid = npcCharacter:FindFirstChildOfClass("Humanoid")
	local plrChar = player.Character
	if not (plrChar and npcRoot and npcHumanoid and npcHumanoid.Health > 0) then
		return
	end

	local plrRoot = plrChar:FindFirstChild("HumanoidRootPart") :: BasePart
	local plrHumanoid = plrChar:FindFirstChildOfClass("Humanoid")
	if not (plrRoot and plrHumanoid and plrHumanoid.Health > 0) then
		return
	end
	if not isPlayerBehind(npcRoot, plrRoot) then
		return
	end

	prompt.Enabled = false

	local prevWalkSpeed = plrHumanoid.WalkSpeed
	local prevJumpPower = plrHumanoid.JumpPower
	local prevNpcWalkSpeed = plrHumanoid.WalkSpeed
	local prevNpcJumpPower = plrHumanoid.JumpPower
	local statusHolder = PlayerStatusRegistry.getPlayerStatusHolder(player)
	local remote = TypedRemotes.ClientboundSetPlayerModuleDisability

	local function restore()
		if plrHumanoid and plrHumanoid.Parent then
			plrHumanoid.WalkSpeed = prevWalkSpeed
			plrHumanoid.JumpPower = prevJumpPower
			npcHumanoid.WalkSpeed = prevNpcWalkSpeed
			npcHumanoid.JumpPower = prevNpcJumpPower
		end
		remote:FireClient(player, true)
		if statusHolder then
			statusHolder:removeStatus(PlayerStatusTypes.CRIMINAL_SUSPICIOUS)
		end
	end

	statusHolder:addStatus(PlayerStatusTypes.CRIMINAL_SUSPICIOUS)
	remote:FireClient(player, false)

	local goalPos = (npcRoot.CFrame * CFrame.new(0, 0, 1.5)).Position
	plrHumanoid:MoveTo(goalPos)

	local startWait = os.clock()
	repeat task.wait()
	until (plrRoot.Position - goalPos).Magnitude < 1
		or (os.clock() - startWait) > MOVE_TIMEOUT
		or not npcRoot.Parent

	if not (plrRoot.Parent and npcRoot.Parent and plrHumanoid.Health > 0) then
		restore()
		return
	end

	plrRoot.CFrame = CFrame.lookAt(plrRoot.Position, npcRoot.Position * Vector3.new(1, 0, 1) + Vector3.new(0, plrRoot.Position.Y, 0))
	plrHumanoid.WalkSpeed = 0
	plrHumanoid.JumpPower = 0

	local crackSound = Instance.new("Sound")
	crackSound.SoundId = "rbxassetid://82963816920497"
	crackSound.PlaybackSpeed = math.random(10, 12) / 10
	crackSound.Parent = (npcCharacter :: any).Head

	local animator = plrHumanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", plrHumanoid)
	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action4

	local loadTimeout = 0
	while track.Length <= 0 and loadTimeout < 1 do
		loadTimeout += task.wait()
	end

	local snapConnection: RBXScriptConnection
	snapConnection = track:GetMarkerReachedSignal("AnimEvent_TakedownSnap"):Once(function()
		if npcHumanoid then
			crackSound:Play()
			npcHumanoid.Health = 0
		end
		snapConnection:Disconnect()
	end)

	-- Idk if this becomes a problem when the player dies 
	track:Play()
	track.Ended:Wait()
	restore()

	task.defer(function()
		if not (npcHumanoid and npcHumanoid.Health <= 0) then
			prompt.Enabled = true
		end
	end)
end

function TakedownService.trackCharacter(npcCharacter: Model, serverLevel: ServerLevel.ServerLevel): ()
	if tracked[npcCharacter] then
		return
	end
	local rootPart = npcCharacter:FindFirstChild("HumanoidRootPart") :: BasePart

	local attachment = Instance.new("Attachment")
	attachment.Name = "Trigger"
	attachment.Parent = rootPart

	local worldPrompt = InteractionPromptBuilder.new()
		:withHoldStatus(`2`)
		:withPrimaryInteractionKey()
		:withOmniDir(true)
		:withTitleKey("ui.prompt.subdue")
		:create(rootPart, serverLevel:getExpressionContext(), attachment)

	worldPrompt.proxPrompt.RequiresLineOfSight = false

	local connection = worldPrompt.proxPrompt.Triggered:Connect(function(player)
		doTakedown(npcCharacter, worldPrompt.proxPrompt, player)
	end)

	tracked[npcCharacter] = { prompt = worldPrompt, connection = connection }
end

function TakedownService.untrackCharacter(npcCharacter: Model): ()
	local entry = tracked[npcCharacter]
	if not entry then return end
	entry.connection:Disconnect()
	entry.prompt:destroy()
	tracked[npcCharacter] = nil
end

return TakedownService