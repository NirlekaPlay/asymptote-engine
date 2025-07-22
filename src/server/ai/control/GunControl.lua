--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Agent = require(ServerScriptService.server.Agent)

--[=[
	@class GunControl

	Lol. Gun control. This is america--
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

		if gunConfig then
			for settingType: string, settingValue: any in pairs(gunConfig) do
				local fbbSettingType = GUN_CONFIG_TO_FBB_SETTINGS[settingType]
				self.fbb.settingsFolder[fbbSettingType].Value = settingValue
			end
		end
		self.fbb.tool.Parent = self.agent.character
	end
end

function GunControl.unequipGun(self: GunControl): ()
	if self:isEquipped() then
		self.equipped = false
		self.fbb.remoteUnequip:Fire()
		task.spawn(function()
			task.wait(1)
			self.fbb.tool.Parent = nil
		end)
	end
end

function GunControl.shoot(self: GunControl, atPos: Vector3): ()
	-- why do we do this again???????
	local originPos = self.agent:getPrimaryPart().Position
	local direction = (atPos - originPos).Unit * 500 -- thats pretty high.
	local rayResult = workspace:Raycast(originPos, direction)

	if rayResult then
		-- what the fuck
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

return GunControl