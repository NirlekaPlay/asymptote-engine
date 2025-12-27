--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HEAD_NAME = "Head"
local SOUNDS_REL_TO_CAMERA = true
local REMOVE_ATT_ON_DISPOSE = false
local WHIZ_SOUND_RANDOM_PLAYBACK_SPEED_MIN = 0.8
local WHIZ_SOUND_RANDOM_PLAYBACK_SPEED_MAX = 1.5

--[=[
	@class WhizzyBullets

	A class used to handle bullet whiz.
	Originally made by PostVivic.
]=]
local WhizzyBullets = {}
WhizzyBullets.__index = WhizzyBullets

export type WhizzyBullets = typeof(setmetatable({} :: {
	whizSound: Sound,
	soundDist: number,
	random: Random,
	currentAttachment: Attachment?,
	currentAttachmentConn: RBXScriptConnection?
}, WhizzyBullets))

function WhizzyBullets.new(whizSound: Sound, soundDist: number): WhizzyBullets
	local self = setmetatable({}, WhizzyBullets)
	
	self.whizSound = whizSound
	self.soundDist = soundDist
	self.random = Random.new()
	self.currentAttachment = nil :: Attachment?
	self.currentAttachmentConn = nil :: RBXScriptConnection?
	
	return self
end

function WhizzyBullets.isCharacterValid(character: Model?): boolean
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

function WhizzyBullets.getCFrameFromP0P1(p0: Vector3, p1: Vector3): (CFrame, number)
	local CF = CFrame.lookAt(p0, p1)
	return CF, (p0 - p1).Magnitude
end

function WhizzyBullets.getDefaultFocalPoint(): CFrame?
	local player = Players.LocalPlayer
	local playerChar = player.Character
	if WhizzyBullets.isCharacterValid(playerChar) then
		-- We will not sacrifice performance for some simple sanity checks.
		-- Don't check if the head is actually a BasePart.
		-- No normal circumstances where there is a Head that is not a BasePart.
		local head = (playerChar :: Model):FindFirstChild(HEAD_NAME) :: BasePart?
		if head then
			return head.CFrame
		end
	end
	return nil
end

function WhizzyBullets.check(
	self: WhizzyBullets,
	origin: CFrame,
	vectorDist: number,
	plrFocalPoint: CFrame?
): number?
	plrFocalPoint = plrFocalPoint or WhizzyBullets.getDefaultFocalPoint()
	if not plrFocalPoint then
		return nil
	end

	local relativeVector = plrFocalPoint.Position - origin.Position
	local dotMagnitude = origin.LookVector:Dot(relativeVector)
	
	if dotMagnitude < 0 or dotMagnitude > vectorDist then
		return nil
	end
	
	local magnitudeWorldSpace = origin.LookVector * dotMagnitude
	local diff = relativeVector - magnitudeWorldSpace
	
	if self.whizSound and (not self.soundDist or self.soundDist >= diff.Magnitude) then
		local attachment = Instance.new("Attachment")
		attachment.Name = "WhizSFXPlayer"
		
		local whizSound = self.whizSound:Clone()
		
		local function positionAttchment()
			if SOUNDS_REL_TO_CAMERA then
				attachment.CFrame = workspace.CurrentCamera.CFrame - diff
			else
				attachment.CFrame = (plrFocalPoint :: CFrame) - diff
			end
		end
		
		-- This is so bad.
		-- But I don't have the mental capacity to fix this right now.
		local attachmentConn
		attachmentConn = RunService.RenderStepped:Connect(function(dt)
			if not attachment or not attachment.Parent then
				if attachmentConn then
					attachmentConn:Disconnect()
				end
				return
			end
			positionAttchment()
		end)
		positionAttchment()
		
		whizSound.Parent = attachment
		attachment.Parent = workspace.Terrain
		
		whizSound.Ended:Once(function()
			if attachmentConn then
				attachmentConn:Disconnect()
			end
			attachment:Destroy()
		end)

		whizSound.PlaybackSpeed = (self.random :: Random):NextNumber(
			WHIZ_SOUND_RANDOM_PLAYBACK_SPEED_MIN, WHIZ_SOUND_RANDOM_PLAYBACK_SPEED_MAX
		)
		
		whizSound:Play()

		self.currentAttachment = attachment
		self.currentAttachmentConn = attachmentConn
		self.whizSound = nil
	end

	return diff.Magnitude
end

function WhizzyBullets.dispose(self: WhizzyBullets): ()
	-- This might be unnecessary. As simply removing all references
	-- to this instances will make the garbage collector do its job
	if REMOVE_ATT_ON_DISPOSE then
		if self.currentAttachment then
			self.currentAttachment:Destroy()
		end
		if self.currentAttachmentConn then
			self.currentAttachmentConn:Disconnect()
		end
	end
	
	setmetatable(self, nil)
	table.clear(self :: any)
end

return WhizzyBullets