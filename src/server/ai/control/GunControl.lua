--!nonstrict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local BodyRotationControl = require(script.Parent.BodyRotationControl)
local Agent = require(ServerScriptService.server.Agent)
local PerceptiveAgent = require(ServerScriptService.server.PerceptiveAgent)
local FBBerylControl = require(ServerScriptService.server.gunsys.framework.fbberyl.FBBerylControl)

local MIN_SPREAD_ANGLE = 10
local MAX_SPREAD_ANGLE = 25
local MIN_FIRE_DELAY = 0.0857 -- the real life fire rate of the FB Beryl. (700 RPM)
local MAX_FIRE_DELAY = 0.1
local DEBUG_MODE = true

--[=[
	@class GunControl

	Lol. Gun control. This is America--
	Anyways, this Control class is made to abstract
	the toolbox gun that is the FB Beryl (FBB).
]=]
local GunControl = {}
GunControl.__index = GunControl

export type GunControl = typeof(setmetatable({} :: {
	agent: Agent.Agent & PerceptiveAgent.PerceptiveAgent,
	equipped: boolean,
	fbb: Fbb,
	fbbControl: FBBerylControl.FBBerylControl,
	rayParams: RaycastParams,
	lastLookPos: Vector3,
	lastShotTime: number
}, GunControl))

type Fbb = {
	tool: Tool,
	settingsFolder: {
		bchambered: NumberValue,
		bspeed: NumberValue,
		inmag: NumberValue,
		magleft: NumberValue,
		maxmagcapacity: NumberValue,
		maxwpenetration: NumberValue,
		mode: StringValue,
		speed: NumberValue
	},
	remoteFire: BindableEvent,
	remoteReload: BindableEvent,
	remoteUnequip: BindableEvent,
	remoteLookAt: BindableEvent
}

export type GunConfg = {
	fireDelay: number,
	chamberedBullet: number,
	roundsInMagazine: number,
	magazineRoundsCapacity: number
}

local GUN_CONFIG_TO_FBB_SETTINGS = {
	fireDelay = "speed",
	chamberedBullet = "bchambered",
	roundsInMagazine = "inmag",
	magazineRoundsCapacity = "maxmagcapacity"
}

local function createRayParams(character: Model)
	local newParams = RaycastParams.new()
	newParams.FilterType = Enum.RaycastFilterType.Exclude
	newParams.FilterDescendantsInstances = { character }

	return newParams
end

local function applySpread(direction: Vector3, angle: number): Vector3
	local randomAxis = Vector3.new(math.random(), math.random(), math.random()).Unit
	local spreadRotation = CFrame.fromAxisAngle(randomAxis, math.random() * angle)
	return (spreadRotation * direction).Unit
end

function GunControl.new(agent: Agent.Agent): GunControl
	local fbb = GunControl.getFbb(agent.character)
	return setmetatable({
		agent = agent,
		equipped = false,
		fbb = fbb,
		fbbControl = FBBerylControl.new(agent.character, fbb.tool.GunModel),
		rayParams = createRayParams(agent.character),
		lastLookPos = Vector3.zero,
		lastShotTime = 0
	}, GunControl)
end

function GunControl.equipGun(self: GunControl, gunConfig: GunConfg?): ()
	if not self:isEquipped() then
		self.equipped = true

		-- sets the custom rotator, as having the FBB equipped makes the
		-- body rotate off
		--local agentRot = self.agent:getBodyRotationControl()
		--agentRot.customRotator = GunControl.rotateBody

		self.fbb.tool.Parent = self.agent.character;
		task.spawn(function()
			(self.fbbControl :: FBBerylControl.FBBerylControl):equip()
		end)
	end
end

function GunControl.unequipGun(self: GunControl): ()
	if self:isEquipped() then
		self.equipped = false

		--local agentRot = self.agent:getBodyRotationControl()
		--agentRot.customRotator = nil

		task.spawn(function()
			task.wait(1)
			self.fbb.tool.Parent = nil
			task.spawn(function()
				(self.fbbControl :: FBBerylControl.FBBerylControl):unequip()
			end)
		end)
	end
end

function GunControl.lookAt(self: GunControl, atPos: Vector3): ()
	if (self.lastLookPos - atPos).Magnitude > 0.1 then
		self.fbbControl:lookAt(atPos)
		self.lastLookPos = atPos
	end
end

function GunControl.shoot(self: GunControl, atPos: Vector3): ()
	if self:isEmpty() then
		self:reload()
		return
	end

	if os.clock() - self.lastShotTime < 60 / 700 then
		return
	end

	local originPos = self.agent:getPrimaryPart().Position
	local difference = (atPos - originPos)
	local distance = difference.Magnitude
	local direction = difference.Unit
	local agentSightRadius = self.agent:getSightRadius()
	--local fireDelay = math.map(distance, 0, agentSightRadius, MIN_FIRE_DELAY, MAX_FIRE_DELAY)
	--self.fbb.settingsFolder[GUN_CONFIG_TO_FBB_SETTINGS.fireDelay].Value = fireDelay

	local spreadAngle = math.map(distance, 0, agentSightRadius, MIN_SPREAD_ANGLE, MAX_SPREAD_ANGLE) -- in degrees, controls how much inaccuracy there is
	local spreadAngleRad = math.rad(spreadAngle)
	
	-- create a random inaccuracy within a cone of 'spreadAngle' radius
	local spreadDirection = applySpread(direction, spreadAngleRad) * 500

	task.spawn(function()
		(self.fbbControl :: FBBerylControl.FBBerylControl):fire(spreadDirection)
	end)

	self.lastShotTime = os.clock()
end

function GunControl.reload(self: GunControl): ()
	task.spawn(function()
		(self.fbbControl :: FBBerylControl.FBBerylControl):reload()
	end)
end

function GunControl.drop(self: GunControl): ()
	self.fbbControl:drop()
end

function GunControl.isEmpty(self: GunControl): boolean
	return self.fbbControl.roundsInMagazine <= 0 and self.fbbControl.roundsChambered <= 0
end

function GunControl.isEquipped(self: GunControl): boolean
	return self.equipped
end

function GunControl.hasRanOutOfAmmo(self: GunControl): boolean
	return self:isEmpty() and (self.fbbControl :: FBBerylControl.FBBerylControl).magazinesLeft <= 0
end

function GunControl.getFbb(toChar: Model): Fbb
	local fbb = ServerStorage:FindFirstChild("FBB") :: Tool
	local clonedFbb = fbb:Clone()

	local settingsFolder = clonedFbb:FindFirstChild("settings") :: Folder
	local settingsFolderTable = {} :: any

	for _, instance in ipairs(settingsFolder:GetChildren()) do
		settingsFolderTable[instance.Name] = instance
	end

	local newFbbObject: Fbb = {
		tool = clonedFbb,
		settingsFolder = settingsFolderTable,
		remoteFire = clonedFbb:FindFirstChild("fire") :: BindableEvent,
		remoteUnequip = clonedFbb:FindFirstChild("unequip") :: BindableEvent,
		remoteReload = clonedFbb:FindFirstChild("reload") :: BindableEvent,
		remoteLookAt = clonedFbb:FindFirstChild("lookat") :: BindableEvent
	}

	return newFbbObject
end

function GunControl.rotateBody(self: BodyRotationControl.BodyRotationControl, deltaTime: number): ()
	local part = self.character:FindFirstChild("HumanoidRootPart") :: BasePart
	local targetCFrame = CFrame.new(part.Position, part.Position + self.targetDirection :: Vector3)
	local rotationOffset = CFrame.Angles(0, math.rad(57), 0)
	targetCFrame = targetCFrame * rotationOffset
	part.CFrame = part.CFrame:Lerp(targetCFrame, deltaTime * self.rotationSpeed)
end

return GunControl