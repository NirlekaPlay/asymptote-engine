--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local BodyRotationControl = require(script.Parent.BodyRotationControl)
local Agent = require(ServerScriptService.server.Agent)

--[=[
	@class GunControl

	Lol. Gun control. This is America--
	Anyways, this Control class is made to abstract
	the toolbox gun that is the FB Beryl (FBB).
]=]
local GunControl = {}
GunControl.__index = GunControl

export type GunControl = typeof(setmetatable({} :: {
	agent: Agent.Agent,
	equipped: boolean,
	fbb: Fbb,
	rayParams: RaycastParams
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
	} & Folder,
	remoteFire: BindableEvent,
	remoteReload: BindableEvent,
	remoteUnequip: BindableEvent
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

function GunControl.new(agent: Agent.Agent): GunControl
	return setmetatable({
		agent = agent,
		equipped = false,
		fbb = GunControl.getFbb(agent.character),
		rayParams = createRayParams(agent.character)
	}, GunControl)
end

function GunControl.equipGun(self: GunControl, gunConfig: GunConfg?): ()
	if not self:isEquipped() then
		self.equipped = true

		-- sets the settings of the FBB
		if gunConfig then
			for settingType: string, settingValue: any in pairs(gunConfig) do
				local fbbSettingType = GUN_CONFIG_TO_FBB_SETTINGS[settingType]
				self.fbb.settingsFolder[fbbSettingType].Value = settingValue
			end
		end

		-- sets the custom rotator, as having the FBB equipped makes the
		-- body rotate off
		local agentRot = self.agent:getBodyRotationControl()
		agentRot.customRotator = GunControl.rotateBody

		self.fbb.tool.Parent = self.agent.character
	end
end

function GunControl.unequipGun(self: GunControl): ()
	if self:isEquipped() then
		self.equipped = false

		local agentRot = self.agent:getBodyRotationControl()
		agentRot.customRotator = nil

		self.fbb.remoteUnequip:Fire()
		task.spawn(function()
			task.wait(1)
			self.fbb.tool.Parent = nil
		end)
	end
end

function GunControl.shoot(self: GunControl, atPos: Vector3): ()
	local originPos = self.agent:getPrimaryPart().Position
	local direction = (atPos - originPos).Unit
	
	local spreadAngle = math.rad(20) -- in degrees, controls how much inaccuracy there is
	
	-- create a random inaccuracy within a cone of 'spreadAngle' radius
	local function applySpread(direction: Vector3, angle: number): Vector3
		local randomAxis = Vector3.new(math.random(), math.random(), math.random()).Unit
		local spreadRotation = CFrame.fromAxisAngle(randomAxis, math.random() * angle)
		return (spreadRotation * direction).Unit
	end

	local spreadDirection = applySpread(direction, spreadAngle) * 500

	local rayResult = workspace:Raycast(originPos, spreadDirection)

	if rayResult then
		self.fbb.remoteFire:Fire("2", rayResult.Position)
	end
end

function GunControl.reload(self: GunControl): ()
	self.fbb.remoteReload:Fire()
end

function GunControl.isEmpty(self: GunControl): boolean
	return self.fbb.settingsFolder.inmag.Value <= 0
end

function GunControl.isEquipped(self: GunControl): boolean
	return self.equipped
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
		remoteReload = clonedFbb:FindFirstChild("reload") :: BindableEvent
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