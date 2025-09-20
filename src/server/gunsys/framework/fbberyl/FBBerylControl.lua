--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local BulletTracerPayload = require(ReplicatedStorage.shared.network.payloads.BulletTracerPayload)
local BulletSimulation = require(ServerScriptService.server.gunsys.framework.BulletSimulation)
local GunSysTypedRemotes = require(ReplicatedStorage.shared.network.remotes.GunSysTypedRemotes)
local Poses = require(ServerScriptService.server.gunsys.framework.fbberyl.Poses)

local CFRAME_ZERO = CFrame.new()
local HEAD_WELD_CFRAME = CFrame.new(0, 1.5, 0)
local RIGHT_ARM_WELD_CFRAME = CFrame.new(1.5, -1.5, 0)
local RIGHT_GRIP_WELD_CFRAME = CFrame.new(-0.612442017, -0.0641784668, 0.243187428, -0.190242305, 0.981636524, -0.0140367029, 0.97735244, 0.188023433, -0.0971002579, -0.0926780254, -0.0321914665, -0.99517554)
local LEFT_ARM_WELD_CFRAME = CFrame.new(-1.5, -1.5, 0)
--
local RIGHT_GRIP_WELD_NAME = "RightGripWeld"
local LEFT_ARM_WELD_NAME = "LeftArmWeld"
local RIGHT_ARM_WELD_NAME = "RightArmWeld"
local HUMANOID_ROOT_PART_WELD_NAME = "HumanoidRootPartWeld"
local HEAD_WELD_NAME = "HeadWeld"

local STATES = {
	UNEQUIPPED = 1,
	EQUIPPING = 2,
	IDLE = 3,
	RELOADING = 4
}

local DAMAGE_PER_LIMBS = {
	["Left Arm"] = 20,
	["Right Arm"] = 20,
	["Left Leg"] = 15,
	["Right Leg"] = 15,
	["Torso"] = 35,
	["HumanoidRootPart"] = 35,
	["UpperTorso"] = 45,
	["LowerTorso"] = 25,
	["Head"] = 50,
}

local SOUND_IDS = {
	BOLT = 456267525,
	MAG_OUT = 268445237,
	MAG_IN = 2546411966,
	MAG_REACH = 7329457810,
	SHOOT = 6862108495
}

local FBBerylControl = {}
FBBerylControl.__index = FBBerylControl

export type FBBerylControl = typeof(setmetatable({} :: {
	character: Model,
	humanoid: Humanoid,
	currentState: number,
	roundsChambered: number,
	roundsInMagazine: number,
	magazinesLeft: number,
	equipTick: number,
	maxMagazineCapacity: number,
	fireRate: number,
	bulletSpeed: number,
	gunModel: Model,
	maxBulletPenetration: number,
	lastTickShot: number,
	gunParts: {
		handle: BasePart,
		lufa: BasePart,
		boltModel: Model,
		boltPart: BasePart,
		magazineModel: Model,
		mainPart: BasePart
	},
	gunWelds: {
		bolt: Weld,
		magazine: Weld,
		trigger: Weld,
		rightGrip: Weld
	},
	characterLimbs: {
		leftArm: BasePart,
		rightArm: BasePart,
		leftLeg: BasePart,
		rightLeg: BasePart,
		torso: BasePart,
		head: BasePart,
		humanoidRootPart: BasePart
	},
	characterWelds: {
		leftArm: Weld,
		rightArm: Weld,
		leftLeg: Weld,
		rightLeg: Weld,
		head: Weld,
		headOffset: Weld,
		torso: Weld
	},
	connections: {
		humanoidDiedConnection: RBXScriptConnection?
	}
}, FBBerylControl))

function FBBerylControl.new(
	character: Model, gunModel: Model
): FBBerylControl
	return setmetatable({
		character = character,
		humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid,
		currentState = STATES.UNEQUIPPED,
		roundsChambered = 0,
		roundsInMagazine = 0,
		magazinesLeft = 10,
		equipTick = 0,
		maxMagazineCapacity = 30,
		fireRate = 700, -- rpm
		bulletSpeed = 50.7,
		gunModel = gunModel,
		maxBulletPenetration = 1,
		lastTickShot = 0,
		gunParts = {
			handle = gunModel:FindFirstChild("Handle") :: BasePart,
			lufa = gunModel:FindFirstChild("lufa") :: BasePart,
			boltModel = gunModel:FindFirstChild("bolt") :: BasePart,
			boltPart = gunModel:FindFirstChild("bolt"):FindFirstChild("boltpart") :: BasePart,
			magazineModel = gunModel:FindFirstChild("mag"),
			mainPart = gunModel:FindFirstChild("mainpart")
		},
		gunWelds = {
			bolt = gunModel:FindFirstChild("mainpart"):WaitForChild("boltweld") :: Weld,
			magazine = nil,
			trigger = nil,
			rightGrip = nil
		},
		characterLimbs = {
			leftArm = character:FindFirstChild("Left Arm"),
			rightArm = character:FindFirstChild("Right Arm"),
			leftLeg = character:FindFirstChild("Left Leg"),
			rightLeg = character:FindFirstChild("Right Leg"),
			torso = character:FindFirstChild("Torso"),
			head = character:FindFirstChild("Head"),
			humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		},
		characterWelds = {
			leftArm = nil,
			rightArm = nil,
			leftLeg = nil,
			rightLeg = nil,
			head = nil,
			headOffset = (function()
				local newWeld = Instance.new("Weld")
				newWeld.Name = "headoffsetholder"
				newWeld.C0 = CFRAME_ZERO
				newWeld.Parent = gunModel:FindFirstChild("Handle") :: BasePart
				return newWeld
			end)(),
			torso = nil
		},
		connections = {
			humanoidDiedConnection = nil :: RBXScriptConnection?
		}
	}, FBBerylControl)
end

--

local function weldParts(part0: BasePart, part1: BasePart, name: string, c0: CFrame): Weld
	local newWeld = Instance.new("Weld")
	newWeld.Part0 = part0
	newWeld.Part1 = part1
	newWeld.Name = name
	newWeld.C0 = c0
	newWeld.Parent = part0
	return newWeld
end

local function tween(
	time: number?,
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?,
	loopCount: number?,
	reverseAfterFinish: boolean?,
	delayTime: number,
	instance: Instance,
	goal: any
): ()
	local info = TweenInfo.new(time, easingStyle, easingDirection, loopCount, reverseAfterFinish, delayTime)
	local anim = TweenService:Create(instance, info, goal)
	anim:Play()
end

--

function FBBerylControl.onToolEquipped(self: FBBerylControl): ()
	self:equip()
end

function FBBerylControl.onToolUnequipped(self: FBBerylControl): ()
	self:unequip()
end

function FBBerylControl.onHumanoidDied(self: FBBerylControl): ()
	self:unequip()
	if (self.gunModel.Parent :: Instance):IsA("Tool") then
		local prevParent = self.gunModel.Parent
		self.gunModel.Parent = workspace
		prevParent.Parent = nil
	end
	local cframe, size = self.gunModel:GetBoundingBox() -- works better if it has a primary part
	local hitboxPartPhysicalProperties = PhysicalProperties.new(1, 0, 0.4)

	local hitboxPart = Instance.new("Part") -- the gun model itself doesnt have any colliders
	hitboxPart.CFrame = cframe
	hitboxPart.Size = size
	hitboxPart.Transparency = 1
	hitboxPart.CanQuery = false
	hitboxPart.Name = "GunHitbox"
	hitboxPart.CustomPhysicalProperties = hitboxPartPhysicalProperties

	local hitboxPartWeldConstraint = Instance.new("WeldConstraint")
	hitboxPartWeldConstraint.Part0 = hitboxPart
	hitboxPartWeldConstraint.Part1 = self.gunParts.mainPart
	hitboxPartWeldConstraint.Parent = hitboxPart

	self.gunModel:SetAttribute("RoundsLeftInMag", self.roundsInMagazine)

	hitboxPart.Parent = self.gunModel

	hitboxPart:ApplyImpulse(self.characterLimbs.humanoidRootPart.CFrame.LookVector * 1.1)
end

--

function FBBerylControl.fire(self: FBBerylControl, at: Vector3): ()
	local backupRemoteTick = self.equipTick
	local firePeriodInSecs = 60 / self.fireRate -- interval between each shot

	if not (self.currentState == STATES.IDLE and tick() > ((self.lastTickShot + firePeriodInSecs) - 0.008) and self.roundsChambered > 0) then
		return
	end

	self.lastTickShot = tick()

	self:animateCharPose(Poses.shoot[1], "shoot", 1, 0.07, backupRemoteTick)
	self:playSound(SOUND_IDS.SHOOT, 0, 1 + math.random(-10, 10) / 65, 0.5)
	self:playSound(SOUND_IDS.BOLT, 0, 1.5 + math.random(-10, 10) / 65, 0.4)
	self:dropShell()

	self.roundsChambered -= 1
	local bulletData = {} :: BulletTracerPayload.BulletTracer
	bulletData.origin = self.gunParts.lufa.Position
	bulletData.direction = (at - self.gunParts.lufa.Position).Unit
	bulletData.humanoidRootPartVelocity = self.characterLimbs.humanoidRootPart.AssemblyLinearVelocity.Magnitude
	bulletData.penetration = self.maxBulletPenetration
	bulletData.seed = os.clock()
	bulletData.size = Vector3.new(self.bulletSpeed / 5, 0.25, 0.25)
	bulletData.muzzleCframe = self.gunParts.lufa.CFrame
	bulletData.speed = self.bulletSpeed
	GunSysTypedRemotes.BulletTracer:FireAllClients(bulletData)
	BulletSimulation.createBulletFromPayload(bulletData, self.character, function(hithum, limb)
		if not (hithum and hithum.Health > 0) then
			return
		end

		local takedamage = DAMAGE_PER_LIMBS[limb.Name]
		if not takedamage then
			takedamage = 15
		end

		if hithum.Health <= takedamage and hithum.Health > 0 then
			hithum.Health = 0
		end

		hithum:TakeDamage(takedamage)
		if hithum.Health <= 0 then
			hithum.Health = 0
		end
	end)
	--
	task.wait(0.07)
	--
	if self.roundsInMagazine > 0 then
		self.roundsChambered += 1
		self.roundsInMagazine -= 1
	end

	self:animateCharPose(Poses.shoot[2], "shoot", 2, 0.1, backupRemoteTick)
end

function FBBerylControl.reload(self: FBBerylControl): ()
	local backupremottick = self.equipTick

	-- Prevents Luau typechecker bullshittery.
	local currentState = self.currentState
	if not (self.roundsInMagazine <= 0 and currentState ~= STATES.RELOADING) then
		return
	end

	self.currentState = STATES.RELOADING
	self:animateCharPose(Poses.reload[1], "reload", 1, 0.3, backupremottick)

	task.wait(0.3)

	if self.magazinesLeft > 0 and self.currentState == STATES.RELOADING then
		self:playSound(SOUND_IDS.MAG_REACH, 0, 1+math.random(-10,10)/65, 2.5)
		local handmagmo, handmagpart = self:cloneMagazineInstance(self.gunModel, "reloadserver")
		local handmagw = Instance.new("Weld", handmagmo)
		handmagw.Name = "handmagweld"
		handmagw.Part0 = self.gunParts.mainPart
		handmagw.Part1 = handmagpart
		handmagw.C0 = CFrame.new(0.771263123, -2.07442856, -2.45114708, 0.108410954, 0.822345078, -0.558561325, -0.0455624163, 0.565389991, 0.823553741, 0.993062019, -0.0638353601, 0.0987635553)
		self:animateCharPose(Poses.reload[2], "reload", 2, 0.25, backupremottick)
		self:animateIndividualPose(Poses.reloadmag[1].mag, handmagw, "reloadmag", 1, "mag", 0.25, backupremottick)
		task.wait(0.25)
		if self.currentState == STATES.RELOADING then
			self:playSound(SOUND_IDS.MAG_OUT, 0, 1+math.random(-10,10)/65, 0.8)
			self:animateCharPose(Poses.reload[3], "reload", 3, 0.1, backupremottick)
			self:animateIndividualPose(Poses.reloadmag[2].mag, handmagw, "reloadmag", 2, "mag", 0.1, backupremottick)
			-- TODO: Remind me to make this client sided.
			--[[local flingmagmo, flingmagpart = clonemag(gunmodel, "throwserver")
			flingmagpart:SetNetworkOwner(nil)
			local magv = Instance.new("BodyVelocity", flingmagpart)
			magv.MaxForce = Vector3.new(1/0,1/0,1/0)
			magv.Velocity = hrp.CFrame.lookVector*math.random(15,20)
			local magav = Instance.new("BodyAngularVelocity", flingmagpart)
			magav.MaxTorque = Vector3.new(1/0,1/0,1/0)
			magav.AngularVelocity = hrp.CFrame.rightVector*math.random(15,20)
			debris:AddItem(magv, 0.1)
			debris:AddItem(flingmagmo, 0.5)
			for i,v in pairs(magmodel:GetChildren()) do
				if v:IsA("BasePart") then
					v.Transparency = 1
				end
			end]]
		end
		task.wait(0.1)
		self:animateCharPose(Poses.reload[4], "reload", 4, 0.15, backupremottick)
		self:animateIndividualPose(Poses.reloadmag[3].mag, handmagw, "reloadmag", 3, "mag", 0.15, backupremottick)
		task.wait(0.15)
		self:animateCharPose(Poses.reload[5], "reload", 5, 0.2, backupremottick)
		self:animateIndividualPose(Poses.reloadmag[4].mag, handmagw, "reloadmag", 4, "mag", 0.2, backupremottick)
		if self.currentState == STATES.RELOADING then
			self:playSound(SOUND_IDS.MAG_IN, 0, 1+math.random(-10,10)/65, 0.8)
		end
		task.wait(0.2)
		handmagmo:Destroy()

		-- yeah no. why.
		for i,v in pairs(self.gunParts.magazineModel:GetChildren()) do
			if v:IsA("BasePart") then
				v.Transparency = 0
			end
		end

		if self.equipTick == backupremottick then
			self.magazinesLeft -= 1
			self.roundsInMagazine = self.maxMagazineCapacity
		end
	end

	if self.roundsChambered <= 0 then
		self:pullBolt(backupremottick)
		task.wait(0.25)
	else
		self:animateCharPose(Poses.equip[3], "equip", 3, 0.45, backupremottick)
	end

	self.currentState = STATES.IDLE

	return
end

function FBBerylControl.equip(self: FBBerylControl): ()
	-- Due to Luau's heavily retarded typechecker, this check is causing the rest
	-- of the FBBerylControl type to be of type `any`, and yes I tried using
	-- strings. It doesn't work.
	if self.currentState == STATES.EQUIPPING then
		return
	end

	self.currentState = STATES.EQUIPPING
	self:connectHumanoidDiedConnection()

	local character = self.character
	self.equipTick = tick() -- wtf is this for then???
	local backuptick = self.equipTick

	self.characterLimbs.torso = character:FindFirstChild("Torso")
	self.characterLimbs.head = character:FindFirstChild("Head")
	self.characterLimbs.leftArm = character:FindFirstChild("Left Arm")
	self.characterLimbs.rightArm = character:FindFirstChild("Right Arm")
	self.characterLimbs.leftLeg = character:FindFirstChild("Left Leg")
	self.characterLimbs.rightLeg = character:FindFirstChild("Right Leg")
	self.characterLimbs.humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	self.gunWelds.rightGrip = weldParts(
		self.characterLimbs.rightArm, self.gunParts.handle, RIGHT_GRIP_WELD_NAME, RIGHT_GRIP_WELD_CFRAME)
	self.characterWelds.leftArm = weldParts(
		self.characterLimbs.head, self.characterLimbs.leftArm, LEFT_ARM_WELD_NAME, LEFT_ARM_WELD_CFRAME)
	self.characterWelds.rightArm = weldParts(
		self.characterLimbs.head, self.characterLimbs.rightArm, RIGHT_ARM_WELD_NAME, RIGHT_ARM_WELD_CFRAME)
	self.characterWelds.torso = weldParts(
		self.characterLimbs.humanoidRootPart, self.characterLimbs.torso, HUMANOID_ROOT_PART_WELD_NAME, CFRAME_ZERO)
	self.characterWelds.head = weldParts(
		self.characterLimbs.humanoidRootPart, self.characterLimbs.head, HEAD_WELD_NAME, HEAD_WELD_CFRAME)

	-- Oh yeah. It's called a *round.* Not a bullet.
	if self.roundsChambered <= 0 and self.roundsInMagazine > 0 then
		self:pullBolt(backuptick)
	else
		self:animateCharPose(Poses.equip[3], "equip", 3, 0.3, backuptick)
		task.wait(0.25) -- Asynchronous bullshit. Feels like a sin in my update-based programming style.
	end

	if self.currentState == STATES.EQUIPPING and self.equipTick == backuptick then
		self.currentState = STATES.IDLE
	end
end

function FBBerylControl.unequip(self: FBBerylControl): ()
	local currentState =  self.currentState
	if currentState == STATES.UNEQUIPPED then
		return
	end

	-- Gets destroyed if theres no further refrence
	-- to these instances.
	self.currentState = STATES.UNEQUIPPED
	self.characterWelds.leftArm.Parent = nil
	self.characterWelds.rightArm.Parent = nil
	--self.characterWelds.leftLeg.Parent = nil
	--self.characterWelds.rightLeg.Parent = nil
	self.gunWelds.rightGrip.Parent = nil
	self.characterWelds.torso.Parent = nil
	self.characterWelds.head.Parent = nil
end

function FBBerylControl.pullBolt(self: FBBerylControl, backupTick: number): ()
	self:animateCharPose(Poses.equip[1], "equip", 1, 0.25, backupTick)

	task.wait(0.25)

	if self.currentState ~= STATES.UNEQUIPPED then
		self:playSound(SOUND_IDS.BOLT, 0, 1 + math.random(-10, 10) / 70, 0.5)
	end

	self:animateCharPose(Poses.equip[2], "equip", 2, 0.15, backupTick)

	task.wait(0.15)

	if self.equipTick == backupTick then
		if self.roundsChambered > 0 then
			self.roundsChambered -= 1
			self:dropShell()
		end
		if self.roundsInMagazine > 0 then
			self.roundsChambered += 1
			self.roundsInMagazine = self.roundsInMagazine - 1
		end
	end

	self:animateCharPose(Poses.equip[3], "equip", 3, 0.3, backupTick)
end

function FBBerylControl.dropShell(self: FBBerylControl): ()
	GunSysTypedRemotes.DropShell:FireAllClients(self.gunParts.boltPart.CFrame)
end

function FBBerylControl.cloneMagazineInstance(self: FBBerylControl, parent: Instance): (Model, BasePart)
	local clonedmag = self.gunParts.magazineModel:Clone()
	local clonedmagpart = clonedmag:FindFirstChild("magpart") :: BasePart
	clonedmag.Name = "reloadserver"
	clonedmag.Parent = parent
	return clonedmag, clonedmagpart
end

--

function FBBerylControl.playSound(
	self: FBBerylControl, soundId: number, timePos: number, playbackSpeed: number, volume: number
): ()
	-- idk if this is problematic since it creates a new sound per play call but eh.
	local newSound = Instance.new("Sound")
	newSound.AudioContent = Content.fromAssetId(soundId)
	newSound.RollOffMinDistance = 1
	newSound.RollOffMaxDistance = 300
	newSound.TimePosition = timePos
	newSound.PlaybackSpeed = playbackSpeed
	newSound.Volume = volume
	newSound.PlayOnRemove = true
	newSound.Parent = self.gunParts.handle
	newSound:Destroy()
end

function FBBerylControl.animateCharPose(
	self: FBBerylControl, poseName: any, clientPose, clientPoseNum, speed: number?, backupTick: number
): ()
	if self.equipTick == backupTick then
		tween(speed, poseName.raw[2], poseName.raw[3], 0, false, 0, self.characterWelds.rightArm, {C0 = poseName.raw[1]})
		tween(speed, poseName.law[2], poseName.law[3], 0, false, 0, self.characterWelds.leftArm, {C0 = poseName.law[1]})
		tween(speed, poseName.gw[2], poseName.gw[3], 0, false, 0, self.gunWelds.rightGrip, {C0 = poseName.gw[1]})
		tween(speed, poseName.tw[2], poseName.tw[3], 0, false, 0, self.characterWelds.torso, {C0 = poseName.tw[1]})
		tween(speed, poseName.hw[2], poseName.hw[3], 0, false, 0, self.characterWelds.headOffset, {C0 = poseName.hw[1]})
		tween(speed, poseName.bw[2], poseName.bw[3], 0, false, 0, self.gunWelds.bolt, {C0 = poseName.bw[1]})
	end
	--tween(speed, easingstylee, easingdirss, 0, false, 0, llegw, {C0 = currentpose.llw})
	--tween(speed, easingstylee, easingdirss, 0, false, 0, rlegw, {C0 = currentpose.rlw})
end

function FBBerylControl.animateIndividualPose(
	self: FBBerylControl, posename, weld, clientpose, clientposenum, clientposedir, speed, backupt
): ()
	if self.equipTick == backupt then
		tween(speed, posename[2], posename[3], 0, false, 0, weld, {C0 = posename[1]})
	end
end

--

function FBBerylControl.connectHumanoidDiedConnection(self: FBBerylControl): ()
	if not self.connections.humanoidDiedConnection then
		self.connections.humanoidDiedConnection = (self.humanoid :: Humanoid).Died:Once(function()
			self:onHumanoidDied()
		end)
	end
end

return FBBerylControl