--!strict

local Debris = game:GetService("Debris")
local StarterPlayer = game:GetService("StarterPlayer")
local GunSysAttributes = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.attributes.GunSysAttributes)

local BULLET_HOLE_TIME = 1
local BULLET_HOLE_INST_NAME = "GunSysBulletHole"
local BULLET_HOLE_WELD_INST_NAME = "GunSysBulletHoleWeld"
local DO_BULLET_HOLE_WELD_TO_ANCHORED_PARTS = true -- Original comment states: 'when you repeatedly weld new stuff to lets say a base it will start bouncing people up'
local DO_CREATE_BULLET_HOLE_FOR_HUMANOID_PARTS = false
local PI = math.pi
local COLORS = {
	BLACK = Color3.new(0, 0, 0),
	MAROON = Color3.fromRGB(100, 0, 0)
}

--[=[
	@class BulletHitHandler
]=]
local BulletHitHandler = {}

function BulletHitHandler.emitBulletParticle(
	part: BasePart,
	color: Color3,
	minSize: number,
	maxSize: number,
	minLift: number,
	maxLift: number,
	speed: number, 
	emissionNormalEnum: Enum.NormalId,
	lifetime: number?
): ()
	-- In the original script, it calls the main logic
	-- with pcall. I don't know the purpose of it,
	-- and the original comment doesn't help much.
	-- But we haven't encountered any issues so far.
	local particleEmitter = Instance.new("ParticleEmitter", part)
	particleEmitter.Color = ColorSequence.new(color)
	particleEmitter.Texture = "rbxassetid://375847957"
	particleEmitter.Name = "gemit"
	particleEmitter.Drag = 10
	particleEmitter.EmissionDirection = emissionNormalEnum
	particleEmitter.Speed = NumberRange.new(speed)
	particleEmitter.Rate = 500
	particleEmitter.Lifetime = NumberRange.new(minLift,maxLift)
	particleEmitter.SpreadAngle = Vector2.new(-20,20)
	particleEmitter.Transparency = NumberSequence.new(0.75, 1)
	particleEmitter.Size = NumberSequence.new(minSize, maxSize)

	-- this is from the original script, which is kinda bad.
	-- though we keep this for now until we script a propper
	-- scheduler.
	task.spawn(function()
		-- this is to prevent the particle emitter texture
		-- from abruptly disappearing upon getting destroyed.
		task.wait(lifetime)
		particleEmitter.Enabled = false
		Debris:AddItem(particleEmitter, 0.5)
	end)
end

function BulletHitHandler.createBulletHole(rayHitPos: Vector3, rayHitNormal: Vector3): SpawnLocation
	local newBulletHole = Instance.new("SpawnLocation")
	newBulletHole.Enabled = false
	newBulletHole.CanCollide = false
	newBulletHole.Color = COLORS.BLACK
	newBulletHole.Shape = Enum.PartType.Cylinder
	newBulletHole.Name = BULLET_HOLE_INST_NAME
	newBulletHole.Size = Vector3.new(0.02, 0.2, 0.2)
	newBulletHole.CFrame = CFrame.new(rayHitPos, rayHitPos + rayHitNormal) * CFrame.Angles(0, PI / 2,0)
	newBulletHole.Parent = workspace

	return newBulletHole
end

function BulletHitHandler.handleBulletHit(rayHitPos: Vector3, rayHitNormal: Vector3, rayHitPart: BasePart): ()
	-- TODO: Only handle bullet hits that are close enough, bullet hits that are too far away
	-- are ignored.
	if rayHitPart.Parent == nil then
		return
	end

	local partIgnoreBulletHolesAttribute = rayHitPart:GetAttribute(GunSysAttributes.IGNORE_BULLET_HOLES)
	if partIgnoreBulletHolesAttribute ~= nil
		and type(partIgnoreBulletHolesAttribute) == "boolean"
		and partIgnoreBulletHolesAttribute == true then
		return
	end

	-- I am pretty perplexed on why the original script uses SpawnLocations.
	-- But the original comment states:
	-- 'spawnlocation because its one of the only baseparts that dont go under tusks basepart limit'
	local bulletHole = BulletHitHandler.createBulletHole(rayHitPos, rayHitNormal)
	Debris:AddItem(bulletHole, BULLET_HOLE_TIME)

	if not rayHitPart.Anchored or rayHitPart.Anchored and DO_BULLET_HOLE_WELD_TO_ANCHORED_PARTS then
		local bulletHoleWeld = Instance.new("Weld", rayHitPart)
		bulletHoleWeld.C0 = rayHitPart.CFrame:ToObjectSpace(bulletHole.CFrame)
		bulletHoleWeld.Part0 = rayHitPart
		bulletHoleWeld.Name = BULLET_HOLE_WELD_INST_NAME
		bulletHoleWeld.Part1 = bulletHole

		if rayHitPart.Parent:FindFirstChildOfClass("Humanoid") then
			if DO_CREATE_BULLET_HOLE_FOR_HUMANOID_PARTS then
				bulletHole.BrickColor = BrickColor.new("Maroon")
				bulletHole.Material = Enum.Material.Pebble
			else
				bulletHole.Transparency = 1
			end
			BulletHitHandler.emitBulletParticle(
				bulletHole, COLORS.MAROON, 0.15, 0.35, 0.1, 0.2, 10, Enum.NormalId.Right, 0.1
			)
		else
			BulletHitHandler.emitBulletParticle(
				bulletHole, rayHitPart.Color, 0.15, 0.35, 0.1, 0.2, 10, Enum.NormalId.Right, 0.1
			)
		end

		Debris:AddItem(bulletHoleWeld, BULLET_HOLE_TIME)
	else
		bulletHole.Anchored = true
	end
end

return BulletHitHandler