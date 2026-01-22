--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollisionGroupTypes = require(ServerScriptService.server.physics.collision.CollisionGroupTypes)
local BulletTracerPayload = require(ReplicatedStorage.shared.network.payloads.BulletTracerPayload)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)

local DEBUG_MODE = false
local PI = math.pi

local activeBullets: { ServerBulletObject } = {}
local activeBulletsInitialCFrame: { [ServerBulletObject]: CFrame } = {}
local sharedRayIgnoreList: { BasePart } = {}
local consumers: { any } = {} -- "trust me bro"

workspace.DescendantAdded:Connect(function(inst)
	if not inst.Parent then
		return
	end

	if inst:IsA("Accessory") or inst.Name == "HumanoidRootPart" then
		table.insert(sharedRayIgnoreList, inst)
	elseif inst:IsA("BasePart") and not inst.CanCollide and not inst.Parent:FindFirstChildOfClass("Humanoid") then
		table.insert(sharedRayIgnoreList, inst)
	end
end)

workspace.DescendantRemoving:Connect(function(WHAT)
	local findthing = table.find(sharedRayIgnoreList, WHAT)
	if findthing then
		table.remove(sharedRayIgnoreList, findthing)
	end
end)

for i,v in pairs(workspace:GetDescendants()) do
	if v:IsA("Accessory") or v:IsA("Hat") or v.Name == "HumanoidRootPart" then
		table.insert(sharedRayIgnoreList, v)
	elseif v:IsA("BasePart") and not v.CanCollide and not v.Parent:FindFirstChildOfClass("Humanoid") then
		table.insert(sharedRayIgnoreList, v)
	end
end

--[=[
	@class BulletSimulation
]=]
local BulletSimulation = {}

export type ServerBulletObject = {
	fromChar: Instance,
	cframe: CFrame,
	currentSpeed: number,
	currentYSpeed: number,
	penetration: number,
	elapsed: number,
	rng: Random,
	raycastParams: RaycastParams,
	size: Vector3,
	damageCallback: (humanoid: Humanoid?, limb: BasePart) -> Humanoid,
	intersectedNpcs: { [Instance]: true }
}

function BulletSimulation.addConsumer(consumer: any): ()
	table.insert(consumers, consumer)
end

function BulletSimulation.getBulletsInitialCFrames(): { [ServerBulletObject]: CFrame }
	return activeBulletsInitialCFrame
end

function BulletSimulation.createBulletFromPayload(bulletData: BulletTracerPayload.BulletTracer, fromChar: Model, damageCallback: (humanoid: Humanoid, limb: BasePart) -> ()): ()
	-- Seeded RNG for deterministic micro-jitter in pierce/deflect only
	local rng = Random.new(bulletData.seed)

	local spreadX = math.rad(rng:NextNumber(-bulletData.humanoidRootPartVelocity, bulletData.humanoidRootPartVelocity) / 10)
	local spreadY = math.rad(rng:NextNumber(-bulletData.humanoidRootPartVelocity, bulletData.humanoidRootPartVelocity) / 10)

	local bulletCFrame =
		CFrame.new(bulletData.origin, bulletData.origin + bulletData.direction)
		* CFrame.Angles(spreadX, (-PI / 2) + spreadY, 0)
		* CFrame.new(-bulletData.size.X / 2, 0, 0)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filter = table.clone(sharedRayIgnoreList)
	table.insert(filter, fromChar)
	rayParams.CollisionGroup = "Bullet"
	rayParams.FilterDescendantsInstances = filter :: any -- stfu

	local bulletObj = {
		fromChar = fromChar,
		cframe = bulletCFrame,
		currentSpeed = bulletData.speed,
		currentYSpeed = 0,
		penetration = bulletData.penetration,
		elapsed = 0,
		rng = rng,
		raycastParams = rayParams,
		size = bulletData.size,
		damageCallback = damageCallback,
		intersectedNpcs = {}
	}

	table.insert(activeBullets, bulletObj)
	local lookAtPoint = bulletData.origin + bulletData.direction
	activeBulletsInitialCFrame[bulletObj] = CFrame.lookAt(bulletData.origin, lookAtPoint)

	-- TODO: This is bad.
	for _, consumer in consumers do
		consumer:onBulletCreated(bulletData.origin, fromChar)
	end
end

function BulletSimulation.update(deltaTime: number): ()
	BulletSimulation.stepBullets(deltaTime)
end

function BulletSimulation.stepBullets(deltaTime: number): ()
	for i = #activeBullets, 1, -1 do
		local bulletObj = activeBullets[i]

		-- Compute "tip" like the old battach at Size.X/2 along rightVector
		local cframe = bulletObj.cframe
		local right = cframe.RightVector
		local tip = cframe.Position + right * (bulletObj.size.X / 2)

		-- Legacy ray for this frame: rightVector * (-currentSpeed * dt * 31)
		local rayOrigin = tip
		local rayDir = right * (-(bulletObj.currentSpeed) * deltaTime * 31)
		local hit = workspace:Raycast(rayOrigin, rayDir, bulletObj.raycastParams)

		if DEBUG_MODE then
			if hit then
				Debris:AddItem(Draw.line(rayOrigin, hit.Position, Color3.new(0, 1, 0)), 0.1)
				Debris:AddItem(Draw.point(hit.Position, Color3.new(0, 1, 1)), 0.1)
			else
				Debris:AddItem(Draw.ray(Ray.new(rayOrigin, rayDir), Color3.new(1, 0, 0)), 0.1)
			end
		end

		if hit then
			local instHit = hit.Instance
			if not instHit or not instHit.Parent then
				-- Advance bookkeeping and continue
				bulletObj.currentSpeed = bulletObj.currentSpeed - (10 * deltaTime)
				bulletObj.currentYSpeed = bulletObj.currentYSpeed + (0.25 * deltaTime)
				bulletObj.size = Vector3.new(math.max(bulletObj.currentSpeed, 0) / 5, 0.25, 0.25)
				if bulletObj.currentSpeed < 0 then
					activeBulletsInitialCFrame[activeBullets[i]] = nil
					table.remove(activeBullets, i)
				end
				continue
			end

			local destroyBullet = false
			local humanoid = instHit.Parent:FindFirstChildOfClass("Humanoid")

			-- TODO: This shit should be handled externally.
			if humanoid or instHit:GetAttribute("PropDamage") == true then
				bulletObj.damageCallback(humanoid, instHit)
			end

			-- Wall depth / piercing check uses tip+right as "look"
			local pierceEnd, pierceLook, pierceNormal =
				BulletSimulation.getWallDepth(hit.Position, tip + right, bulletObj.penetration, instHit)

			if humanoid then
				-- Legacy small penalty on penetration after hitting humanoid
				bulletObj.penetration -= 0.3
			end

			if pierceEnd and pierceLook and pierceNormal then
				-- Pierce: re-seat bullet on far side with small deterministic jitter
				local wallThickness = (hit.Position - pierceEnd).Magnitude
				local jitterX = bulletObj.rng:NextNumber(-20, 20) / 400
				local jitterY = (-PI / 2) + (bulletObj.rng:NextNumber(-20, 20) / 400)

				bulletObj.cframe =
					CFrame.new(pierceEnd, pierceLook)
					* CFrame.Angles(jitterX, jitterY, 0)
					* CFrame.new(-(bulletObj.size.X) / 1.9, 0, 0)

				bulletObj.penetration -= wallThickness
				bulletObj.currentSpeed -= wallThickness * 5

			elseif bulletObj.currentSpeed > 0 and bulletObj.penetration > 0 and humanoid == nil then
				-- Deflect: deterministic reflect with legacy factor
				local factor = 1 + (bulletObj.rng:NextNumber(1, 10) / 10)
				local reflec = hit.Position - right - (factor * right:Dot(hit.Normal) * -hit.Normal)

				bulletObj.cframe =
					CFrame.new(hit.Position, reflec)
					* CFrame.Angles(0, -PI / 2, 0)
					* CFrame.new(-(bulletObj.size.X) / 2, 0, 0)

				bulletObj.currentSpeed -= (bulletObj.currentSpeed / 10)
				bulletObj.penetration  -= (0.25 + (bulletObj.penetration) / 10)
			else
				destroyBullet = true
			end

			if destroyBullet then
				activeBulletsInitialCFrame[activeBullets[i]] = nil
				table.remove(activeBullets, i)
				continue
			end
		else
			-- No hit this frame: advance along local X negative, with slight Z spin
			bulletObj.cframe = bulletObj.cframe * CFrame.new(-(bulletObj.currentSpeed) * deltaTime * 30, 0, 0)
			if bulletObj.currentYSpeed < 3 then
				bulletObj.cframe = bulletObj.cframe * CFrame.Angles(0, 0, (bulletObj.currentYSpeed / 10) * deltaTime * 30)
			end
		end

		------------------------------------------------------------------------------------------------------------------------
		-- Notify NPCs when a bullet passed them
		------------------------------------------------------------------------------------------------------------------------

		local pathStart = rayOrigin
		local pathEnd = bulletObj.cframe.Position
		local pathVector = pathEnd - pathStart

		local overlapParams = OverlapParams.new()
		overlapParams.CollisionGroup = CollisionGroupTypes.QUERY_CHECK_NPC_CHARS
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = { bulletObj.fromChar }

		local whistleRadius = 25
		local whistleRadiusDoubled = whistleRadius * 2
		local boundsSize = Vector3.new(
			math.abs(pathVector.X) + whistleRadiusDoubled,
			math.abs(pathVector.Y) + whistleRadiusDoubled,
			math.abs(pathVector.Z) + whistleRadiusDoubled
		)
		local boundsCenter = pathStart:Lerp(pathEnd, 0.5)

		local nearbyParts = workspace:GetPartBoundsInBox(CFrame.new(boundsCenter), boundsSize, overlapParams)

		local intersectedNpcs = bulletObj.intersectedNpcs
		for _, part in nearbyParts do
			if part.Parent and intersectedNpcs[part.Parent] then
				continue
			end

			if part.Parent then
				local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
				if not humanoid or humanoid.Health <= 0 then
					continue
				end
			else
				continue
			end

			local npcPos = part.Position
			local relativePos = npcPos - pathStart

			local t = math.clamp(relativePos:Dot(pathVector) / pathVector.Magnitude ^ 2, 0, 1)
			local closestPoint = pathStart + (t * pathVector)
			local distance = (npcPos - closestPoint).Magnitude

			if distance <= whistleRadius then
				local rayResult = workspace:Raycast(closestPoint, (part.Position - closestPoint).Unit * distance)
				if not rayResult or not rayResult.Instance:IsDescendantOf(part.Parent) then
					continue
				end
				intersectedNpcs[part.Parent] = true
				
				part.Parent:SetAttribute("RecentShotAtOrigin", closestPoint)
			end
		end

		------------------------------------------------------------------------------------------------------------------------
		-- End
		------------------------------------------------------------------------------------------------------------------------

		-- Legacy per-frame decay and visual width scaling
		bulletObj.currentSpeed -= (10 * deltaTime)
		bulletObj.currentYSpeed += (0.25 * deltaTime)

		bulletObj.size = Vector3.new(math.max(bulletObj.currentSpeed, 0) / 5, 0.25, 0.25)

		-- Die when speed flips negative (legacy behavior)
		if bulletObj.currentSpeed < 0 then
			activeBulletsInitialCFrame[activeBullets[i]] = nil
			table.remove(activeBullets, i)
		end
	end
end

function BulletSimulation.getWallDepth(
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

return BulletSimulation