--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local SharedConstants = require(StarterPlayer.StarterPlayerScripts.client.modules.SharedConstants)
local Particles = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.Particles)
local WhizzyBullets = require(StarterPlayer.StarterPlayerScripts.client.modules.gunsys.framework.handlers.WhizzyBullets)
local BulletTracerPayload = require(ReplicatedStorage.shared.network.payloads.BulletTracerPayload)
local BulletHitHandler = require(script.Parent.BulletHitHandler)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)

local LOCAL_PLAYER = Players.LocalPlayer
local BULLET_INST_NAME = "GunSysBullet"
local MUZZLE_FLASH_INST_NAME = "GunSysMuzzleFlash"
local MUZZLE_FLASH_LIFE_TIME = 0.025
local PI = math.pi
local WHITE = Color3.new(1, 1, 1)
local PISS_YELLOW = Color3.new(1, 0.866667, 0) -- (≖_≖ )

local activeBullets: { BulletObject } = {}

--[=[
	@class BulletTracerHandler
]=]
local BulletTracerHandler = {}

export type BulletObject = {
	instance: BasePart,
	currentSpeed: number,
	currentYSpeed: number,
	penetration: number,
	elapsed: number,
	whiz: WhizzyBullets,
	rng: Random,
	raycastParams: RaycastParams,
}

function BulletTracerHandler.onReceiveTracerData(bulletTracerData: BulletTracerPayload.BulletTracer): ()
	-- Seeded RNG for deterministic micro-jitter in pierce/deflect only
	local rng = Random.new(bulletTracerData.seed)

	local bulletPart = BulletTracerHandler.createNewBulletPart(
		bulletTracerData.origin,
		bulletTracerData.direction,
		bulletTracerData.speed,
		bulletTracerData.humanoidRootPartVelocity,
		rng
	)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filter = {}
	if LOCAL_PLAYER and LOCAL_PLAYER.Character then
		table.insert(filter, LOCAL_PLAYER.Character)
	end
	rayParams.CollisionGroup = "Bullet"
	rayParams.FilterDescendantsInstances = filter

	BulletTracerHandler.muzzleFlash(bulletTracerData.muzzleCframe, Vector3.new(2, 0.6, 0.6), math.random(1, 15) / 10)

	table.insert(activeBullets, {
		instance = bulletPart,
		currentSpeed = bulletTracerData.speed, -- legacy: currentbspeed
		currentYSpeed = 0,                     -- legacy: currentbYspeed
		penetration = bulletTracerData.penetration,
		elapsed = 0,
		rng = rng,
		whiz = WhizzyBullets.new(workspace:WaitForChild("Dirt Rico Pack 20 (SFX)"), 2),
		raycastParams = rayParams,
	})
end

function BulletTracerHandler.update(deltaTime: number): ()
	for i = #activeBullets, 1, -1 do
		local bulletObj = activeBullets[i]
		local inst = bulletObj.instance

		-- Compute "tip" like the old battach at Size.X/2 along rightVector
		local cframe = inst.CFrame
		local right = cframe.RightVector
		local tip = cframe.Position + right * (inst.Size.X / 2)

		-- Legacy ray for this frame: rightVector * (-currentSpeed * dt * 31)
		local rayOrigin = tip
		local rayDir = right * (-(bulletObj.currentSpeed) * deltaTime * 31)
		local hit = workspace:Raycast(rayOrigin, rayDir, bulletObj.raycastParams)

		-- Bullet whizz data:
		local cf, dist = WhizzyBullets.GetCFrameFromP0P1(rayOrigin, rayOrigin + rayDir)
		bulletObj.whiz:Check(cf, dist)


		if SharedConstants.DEBUG_BULLET_TRACERS then
			if hit then
				Debris:AddItem(Draw.line(rayOrigin, hit.Position, Color3.new(0, 1, 0)), 0.1)
				Debris:AddItem(Draw.point(hit.Position, Color3.new(0, 1, 1)), 0.1)
			else
				Debris:AddItem(Draw.ray(Ray.new(rayOrigin, rayDir), Color3.new(1, 0, 0)), 0.1)
			end
		end

		if hit then
			local instHit = hit.Instance
			if not instHit.Parent then
				-- Advance bookkeeping and continue
				bulletObj.currentSpeed = bulletObj.currentSpeed - (10 * deltaTime)
				bulletObj.currentYSpeed = bulletObj.currentYSpeed + (0.25 * deltaTime)
				inst.Size = Vector3.new(math.max(bulletObj.currentSpeed, 0) / 5, 0.25, 0.25)
				if bulletObj.currentSpeed < 0 then
					inst:Destroy()
					table.remove(activeBullets, i)
				end
				continue
			end

			local destroyBullet = false
			local humanoid = instHit.Parent:FindFirstChildOfClass("Humanoid")

			-- Client visual hit callback
			BulletHitHandler.handleBulletHit(hit.Position, hit.Normal, instHit)

			-- Wall depth / piercing check uses tip+right as "look"
			local pierceEnd, pierceLook, pierceNormal =
				BulletTracerHandler.getWallDepth(hit.Position, tip + right, bulletObj.penetration, instHit)

			if humanoid then
				-- Legacy small penalty on penetration after hitting humanoid
				bulletObj.penetration -= 0.3
			end

			if pierceEnd and pierceLook and pierceNormal then
				-- Pierce: re-seat bullet on far side with small deterministic jitter
				local wallThickness = (hit.Position - pierceEnd).Magnitude
				local jitterX = bulletObj.rng:NextNumber(-20, 20) / 400
				local jitterY = (-PI / 2) + (bulletObj.rng:NextNumber(-20, 20) / 400)

				inst.CFrame =
					CFrame.new(pierceEnd, pierceLook)
					* CFrame.Angles(jitterX, jitterY, 0)
					* CFrame.new(-(inst.Size.X) / 1.9, 0, 0)

				bulletObj.penetration -= wallThickness
				bulletObj.currentSpeed -= wallThickness * 5

				if bulletObj.currentSpeed > 0 then
					-- Visual confirmation again (legacy behavior)
					BulletHitHandler.handleBulletHit(hit.Position, hit.Normal, instHit)
				end
			elseif bulletObj.currentSpeed > 0 and bulletObj.penetration > 0 and humanoid == nil then
				-- Deflect: deterministic reflect with legacy factor
				local factor = 1 + (bulletObj.rng:NextNumber(1, 10) / 10)
				local reflec = hit.Position - right - (factor * right:Dot(hit.Normal) * -hit.Normal)

				inst.CFrame =
					CFrame.new(hit.Position, reflec)
					* CFrame.Angles(0, -PI / 2, 0)
					* CFrame.new(-(inst.Size.X) / 2, 0, 0)

				bulletObj.currentSpeed -= (bulletObj.currentSpeed / 10)
				bulletObj.penetration  -= (0.25 + (bulletObj.penetration) / 10)
			else
				destroyBullet = true
			end

			if destroyBullet then
				inst:Destroy()
				table.remove(activeBullets, i)
				continue
			end
		else
			-- No hit this frame: advance along local X negative, with slight Z spin
			inst.CFrame = inst.CFrame * CFrame.new(-(bulletObj.currentSpeed) * deltaTime * 30, 0, 0)
			if bulletObj.currentYSpeed < 3 then
				inst.CFrame = inst.CFrame * CFrame.Angles(0, 0, (bulletObj.currentYSpeed / 10) * deltaTime * 30)
			end
		end

		-- Legacy per-frame decay and visual width scaling
		bulletObj.currentSpeed -= (10 * deltaTime)
		bulletObj.currentYSpeed += (0.25 * deltaTime)

		inst.Size = Vector3.new(math.max(bulletObj.currentSpeed, 0) / 5, 0.25, 0.25)

		-- Die when speed flips negative (legacy behavior)
		if bulletObj.currentSpeed < 0 then
			inst:Destroy()
			table.remove(activeBullets, i)
		end
	end
end

function BulletTracerHandler.getWallDepth(
	hitPos: Vector3,
	direction: Vector3,
	penetrationAmount: number,
	wall: BasePart
): (Vector3?, Vector3?, Vector3?)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { wall }

	local startPos = hitPos + (hitPos - direction).Unit * penetrationAmount
	local castDir = startPos + (startPos - hitPos).Unit * -((startPos - hitPos).Magnitude)
	local depthRay = workspace:Raycast(startPos, (startPos - castDir).Unit * (-penetrationAmount), rayParams)

	if depthRay then
		return depthRay.Position, startPos, depthRay.Normal
	end

	return nil, nil, nil
end

function BulletTracerHandler.createNewBulletPart(
	origin: Vector3,
	direction: Vector3,
	bulletSpeed: number,
	humanoidRootPartVelocity: number,
	rng: Random
): BasePart

	local bullet = Instance.new("Part")
	bullet.Name = BULLET_INST_NAME
	bullet.Anchored = true
	bullet.CanCollide = false
	bullet.CanQuery = false
	bullet.Transparency = 0.3
	bullet.Material = Enum.Material.Neon
	bullet.Size = Vector3.new(bulletSpeed / 5, 0.25, 0.25)
	bullet.CollisionGroup = "Bullet"

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = bullet

	local spreadX = math.rad(rng:NextNumber(-humanoidRootPartVelocity, humanoidRootPartVelocity) / 10)
	local spreadY = math.rad(rng:NextNumber(-humanoidRootPartVelocity, humanoidRootPartVelocity) / 10)

	bullet.CFrame =
		CFrame.new(origin, origin + direction)
		* CFrame.Angles(spreadX, (-PI / 2) + spreadY, 0)
		* CFrame.new(-bullet.Size.X / 2, 0, 0)

	bullet.Parent = workspace
	return bullet
end

function BulletTracerHandler.muzzleFlash(muzzleCframe: CFrame, size: Vector3, transparency: number)
	local muzzleFlashPart = Instance.new("Part")

	local specialMesh = Instance.new("SpecialMesh")
	specialMesh.MeshType = Enum.MeshType.Sphere
	specialMesh.Parent = muzzleFlashPart

	local muzzleFlashLight = Instance.new("PointLight")
	muzzleFlashLight.Brightness = 1 - transparency
	muzzleFlashPart.Size = size
	muzzleFlashPart.Name = MUZZLE_FLASH_INST_NAME
	muzzleFlashPart.Transparency = transparency
	muzzleFlashPart.Color = PISS_YELLOW
	muzzleFlashPart.CanCollide = false
	muzzleFlashPart.CanQuery = false
	muzzleFlashPart.Anchored = true
	muzzleFlashPart.Material = Enum.Material.Neon
	muzzleFlashPart.CFrame = muzzleCframe * CFrame.new((-size.X / 2) - 0.3, 0, 0)
	muzzleFlashPart.Parent = workspace

	local particlePart = Instance.new("Part")
	particlePart.Anchored = true
	particlePart.Transparency = 1
	particlePart.CanCollide = false
	particlePart.CanQuery = false
	particlePart.AudioCanCollide = false
	particlePart.Position = muzzleCframe.Position
	particlePart.CFrame = CFrame.lookAt(muzzleCframe.Position, muzzleFlashPart.Position) -- this is stupid
	particlePart.Size = Vector3.one
	particlePart.Parent = workspace

	Particles.emitParticle(particlePart, WHITE, 0.15, 0.35, 0.1, 0.2, 10, Enum.NormalId.Left, MUZZLE_FLASH_LIFE_TIME)
	Debris:AddItem(muzzleFlashPart, MUZZLE_FLASH_LIFE_TIME)
end

return BulletTracerHandler