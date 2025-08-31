--!strict

local ATTATCHMENT_CFRAMES = {
	["Neck"] = {CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1), CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1)},
	["Left Shoulder"] = {CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1), CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1)},
	["Right Shoulder"] = {CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	["Left Hip"] = {CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
	["Right Hip"] = {CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
}

local RAGDOLL_INSTANCE_NAMES = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}

local RAGDOLL_BOOL_VALUE_NAME = "IsRagdoll"
local RAGDOLL_COLLIDER_PART_NAME = "RagdollColliderPart"
local RAGDOLL_ATTATCHMENT_NAME = "RagdollAttachment"
local RAGDOLL_CONSTRAINT_NAME = "RagdollConstraint"

--[=[
	@class RagdollControl

	Allows Agents to have ragdolls upon death or explosion.
	Based on the NPC Version of the Perfect R6 Ragdoll
	by CompletedLoop.
]=]
local RagdollControl = {}
RagdollControl.__index = RagdollControl

export type RagdollControl = typeof(setmetatable({} :: {
	character: Model,
	torso: BasePart,
	humanoid: Humanoid,
	ragdollBoolValue: BoolValue,
	--
	_boolValueChangedConnection: RBXScriptConnection?,
	_characterDestroyedConnection: RBXScriptConnection?,
	_diedConnection: RBXScriptConnection?,
}, RagdollControl))

function RagdollControl.new(character: Model): RagdollControl
	local self = {
		character = character,
		torso = character:WaitForChild("Torso") :: BasePart,
		humanoid = RagdollControl.setupHumanoid(character),
		ragdollBoolValue = RagdollControl.setupBoolValue(character),
		--
		_boolValueChangedConnection = nil :: RBXScriptConnection?,
		_characterDestroyedConnection = nil :: RBXScriptConnection?,
		_diedConnection = nil :: RBXScriptConnection?,
	}
	setmetatable(self, RagdollControl)
	self:connectMethods()

	return self
end

function RagdollControl.ragdoll(self: RagdollControl, value: boolean)
	for _, basePart in ipairs(self.character:GetChildren()) do
		if basePart:IsA("BasePart") then
			basePart:SetNetworkOwner(nil)
		end
	end

	if value then
		self.humanoid.PlatformStand = true
		self.humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
		self.humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		self:replaceJoints()
		self:pushBody()
	else 
		self:resetJoints()
		self.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		self.humanoid.PlatformStand = false
	end
end

function RagdollControl.pushBody(self: RagdollControl): ()
	-- The reason why I push NPCs backwards is that I want Players to
	-- see the NPCs dead face when they die.
	self.torso:ApplyImpulse(-self.torso.CFrame.LookVector * 250)
end

function RagdollControl.createColliderPart(self: RagdollControl, part: Part): ()
	if not part then return end

	local rp = Instance.new("Part")
	rp.Name = RAGDOLL_COLLIDER_PART_NAME
	rp.Size = part.Size / 1.7
	rp.Massless = true
	rp.CFrame = part.CFrame
	rp.Transparency = 1

	local wc = Instance.new("WeldConstraint")
	wc.Part0 = rp
	wc.Part1 = part

	wc.Parent = rp
	rp.Parent = part
end

function RagdollControl.resetJoints(self: RagdollControl): ()
	if self.humanoid.Health < 1 then return end

	for _, instance in pairs(self.character:GetDescendants()) do
		if RAGDOLL_INSTANCE_NAMES[instance.Name] then
			instance:Destroy()
		end

		if instance:IsA("Motor6D") then
			instance.Enabled = true;
		end
	end
end

function RagdollControl.replaceJoints(self: RagdollControl): ()
	for _, motor: Motor6D in pairs(self.character:GetDescendants()) do
		if not motor:IsA("Motor6D") then
			continue
		end

		if not ATTATCHMENT_CFRAMES[motor.Name] then return end

		motor.Enabled = false;
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.CFrame = ATTATCHMENT_CFRAMES[motor.Name][1]
		a1.CFrame = ATTATCHMENT_CFRAMES[motor.Name][2]

		a0.Name = RAGDOLL_ATTATCHMENT_NAME
		a1.Name = RAGDOLL_ATTATCHMENT_NAME

		self:createColliderPart(motor.Part1 :: Part)

		local b = Instance.new("BallSocketConstraint")
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Name = RAGDOLL_CONSTRAINT_NAME

		b.Radius = 0.15
		b.LimitsEnabled = true
		b.TwistLimitsEnabled = false
		b.MaxFrictionTorque = 0
		b.Restitution = 0
		b.UpperAngle = 90
		b.TwistLowerAngle = -45
		b.TwistUpperAngle = 45

		if motor.Name == "Neck" then
			b.TwistLimitsEnabled = true
			b.UpperAngle = 45
			b.TwistLowerAngle = -70
			b.TwistUpperAngle = 70
		end

		a0.Parent = motor.Part0
		a1.Parent = motor.Part1
		b.Parent = motor.Parent
	end
end

function RagdollControl.setupHumanoid(character: Model): Humanoid
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = true

	return humanoid
end

function RagdollControl.setupBoolValue(character: Model): BoolValue
	local ragdollBoolValue = character:FindFirstChild(RAGDOLL_BOOL_VALUE_NAME) :: BoolValue?
	if not ragdollBoolValue then
		ragdollBoolValue = Instance.new("BoolValue")
		ragdollBoolValue.Name = RAGDOLL_BOOL_VALUE_NAME
		ragdollBoolValue.Value = false
		ragdollBoolValue.Parent = character
	end

	return ragdollBoolValue :: BoolValue
end

function RagdollControl.connectMethods(self: RagdollControl): ()
	self._characterDestroyedConnection = self.character.Destroying:Once(function()
		if self._boolValueChangedConnection then
			self._boolValueChangedConnection:Disconnect()
			self._boolValueChangedConnection = nil
		end
	end)

	self._boolValueChangedConnection = self.ragdollBoolValue.Changed:Connect(function(ragdoll)
		self:ragdoll(ragdoll)
	end)

	self._diedConnection = self.humanoid.Died:Once(function()
		self.ragdollBoolValue.Value = true
		self:pushBody()
	end)
end

return RagdollControl