--PURELY CLIENTSIDE API! Do not use this on the server
--Whizzy bullets module made by PostVivic

--[[
USAGE

Helper Functions:
	WhizzyBullets.IsAlive(Character:Model?)->boolean
		Alterable table that checks if your character is alive (change it if you arent using humanoids)

	WhizzyBullets.GetCFrameFromP0P1(P0:Vector3, P1:Vector3)->(CFrame, number)
		Gets the cframe and VectorDistance from two world space points
	
	WhizzyBullets.DefaultFocalPoint()->CFrame
		Gets the default focal point if one isn't provided

Properties:
	WhizSFX: Sound
		the stored whiz sound effects
	
	SFXDist: number
		min dist the sfx will try to play at
	
	Attachment: Attachment
		the instanced Attachment (if there is any)
	
	AttConnection: RBXScriptConnection
		The event handler for moving the attachment every frame
	
Methods:
	Check(Origin:CFrame, VectorDistance:number, PlayerFocalPoint:CFrame?)->number
		Runs a check, Origin and VectorDistance can be swapped out with GetCFrameFromP0P1 like
		Check(WhizzyBullets.GetCFrameFromP0P1(p0, p1))
	
	Dispose()->nil
		Disposes of the current WhizzyBulletsObject and destroys all of it's connections

Constructors:
	WhizzyBullets.new(WhizSFX:Sound, SFXDist:number)->WhizzyBulletsObject

]]

local WhizzyBullets = {}
WhizzyBullets.__index = WhizzyBullets

--CONFIG
local HEAD_NAME = "Head" --the name of the head in characters, make a cframe for a primary part offset, make nil for camera
local LOG_MODE = true --log errors or no

local SOUNDS_RELTO_CAMERA = true--True if the sound should be positioned relative to the camera, false if it should be positioned 
local REMOVE_ATT_ON_DISPOSE = false--true if you want the attachment to be removed on dispose

--SERVICES
local RunService = game:GetService("RunService")

--if you arent using humanoids, alter this so its true if the player is alive and false if they are dead
function WhizzyBullets.IsAlive(Character)
	if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
		return true
	end
end

function WhizzyBullets.GetCFrameFromP0P1(P0:Vector3, P1:Vector3)
	local CF = CFrame.lookAt(P0, P1)
	return CF, (P0-P1).Magnitude
end

function WhizzyBullets.DefaultFocalPoint():CFrame?
	local Plr = game.Players.LocalPlayer
	if WhizzyBullets.IsAlive(Plr.Character) then
		if not HEAD_NAME then
			return workspace.CurrentCamera.CFrame
		elseif typeof(HEAD_NAME) == "string" then
			local Head = Plr.Character:FindFirstChild(HEAD_NAME)
			Log(Head, "%s is not a valid object in the head", HEAD_NAME)
			return Head.CFrame
		elseif typeof(HEAD_NAME) == "CFrame" then
			return Plr.Character.PrimaryPart and Plr.Character.PrimaryPart.CFrame * HEAD_NAME
		else
			Log(true, "HEAD_NAME Needs to be a valid CFrame, String, or nil")
		end
	end
	return
end

function WhizzyBullets:Dispose()
	if REMOVE_ATT_ON_DISPOSE then
		if self.Attachment then self.Attachment:Destroy() end
		if self.AttConnection then self.AttConnection:Disconnect() end
	end
	
	setmetatable(self, nil)
	table.clear(self)
end

function WhizzyBullets:Check(Origin:CFrame, VectorDistance:number, PlayerFocalPoint:CFrame?)
	local PlayerFocalPoint = PlayerFocalPoint or WhizzyBullets.DefaultFocalPoint()
	if not PlayerFocalPoint then return end
	
	local RelativeVector = PlayerFocalPoint.Position - Origin.Position
	local DotMagnitude = Origin.LookVector:Dot(RelativeVector)
	
	if DotMagnitude < 0 or DotMagnitude > VectorDistance then
		return
	end
	
	local MagRealSpace = Origin.LookVector * DotMagnitude
	local Difference = RelativeVector - MagRealSpace
	
	if self.WhizSFX and (not self.SFXDist or self.SFXDist >= Difference.Magnitude) then
		local Attachment = Instance.new("Attachment")
		Attachment.Name = "WhizSFXPlayer"
		
		local WhizSFX:Sound = self.WhizSFX:Clone()
		
		local function PositionAttachment()
			if SOUNDS_RELTO_CAMERA then
				Attachment.CFrame = workspace.CurrentCamera.CFrame - Difference
			else
				Attachment.CFrame = PlayerFocalPoint - Difference
			end
		end
		
		local AttConnection
		AttConnection = RunService.RenderStepped:Connect(function(dt)
			if not Attachment or not Attachment.Parent then AttConnection:Disconnect() return end
			PositionAttachment()
		end)
		PositionAttachment()
		
		--Attachment.Visible = true
		
		WhizSFX.Parent = Attachment
		Attachment.Parent = workspace.Terrain
		
		WhizSFX.Ended:Once(function()
			AttConnection:Disconnect()
			Attachment:Destroy()
		end)
		
		WhizSFX:Play()
		
		self.Attachment = Attachment
		self.AttConnection = AttConnection
		self.WhizSFX = nil
	end
	
	return Difference.Magnitude
end

function WhizzyBullets.new(WhizSFX, SFXDist)
	local self = setmetatable({}, WhizzyBullets)
	
	self.WhizSFX = WhizSFX
	self.SFXDist = SFXDist
	
	return self
end


function Log(Assertion, Msg, ...)
	if not Assertion then
		if LOG_MODE then
			if ... then
				error(string.format(Msg, ...))
			else
				error(Msg)
			end
		else
			coroutine.yield()
		end
	end
end

return WhizzyBullets