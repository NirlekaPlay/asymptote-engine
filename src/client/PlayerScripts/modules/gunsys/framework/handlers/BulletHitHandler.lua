--!strict

local Debris = game:GetService("Debris")
local StarterPlayer = game:GetService("StarterPlayer")
local Particles = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.Particles)
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

function BulletHitHandler.createBulletHole(rayHitPos: Vector3, rayHitNormal: Vector3): BasePart
	local newBulletHole = Instance.new("Part")
	newBulletHole.CanQuery = false
	newBulletHole.AudioCanCollide = false
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
			Particles.emitParticle(
				bulletHole, COLORS.MAROON, 0.15, 0.35, 0.1, 0.2, 10, Enum.NormalId.Right, 0.1
			)
		else
			Particles.emitParticle(
				bulletHole, rayHitPart.Color, 0.15, 0.35, 0.1, 0.2, 10, Enum.NormalId.Right, 0.1
			)
		end

		Debris:AddItem(bulletHoleWeld, BULLET_HOLE_TIME)
	else
		bulletHole.Anchored = true
	end
end

return BulletHitHandler