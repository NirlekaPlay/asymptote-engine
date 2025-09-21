--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local PlantEvent = ReplicatedStorage.remotes.c4.PlantEvent
local DetonateEvent = ReplicatedStorage.remotes.c4.DetonateEvent

local TIME_TO_ARM_C4 = 0.8
local TIME_TO_DETONATE_C4 = 0.8
local C4_REFERENCE_INSTANCE = ReplicatedStorage:WaitForChild("ExplFolder"):WaitForChild("ExplosiveR") :: BasePart

local STATES = {
	ARMING = "ARMING",
	ARMED = "ARMED",
	DETONATING = "DETONATING",
	DETONATED = "DETONATED"
}

local Attributes = {
	STATE = "State",
	ARMING_TIMER = "ArmingTimer",
	DETONATING_TIMER  = "DetonationTimer",
	OWNER = "Owner"
}

local playersPlacedC4Map: { [Player]: { [BasePart]: true } } = {}
local detonateC4Proxy = nil -- hac.

local EntityManger = require(ServerScriptService.server.entity.EntityManager) -- FOR NOW --------------------------------------------

local function detonatePlayerC4s(player: Player): ()
	-- i know that c4s are unique to their detonators, but its more fun
	-- if the players can detonate them even after death

	if not playersPlacedC4Map[player] then
		return
	end

	if next(playersPlacedC4Map[player]) == nil then
		return
	end

	for c4 in pairs(playersPlacedC4Map[player]) do
		if c4:GetAttribute(Attributes.STATE) ~= STATES.ARMED then
			continue
		end

		c4:SetAttribute(Attributes.STATE, STATES.DETONATING)
		c4:SetAttribute(Attributes.DETONATING_TIMER, TIME_TO_DETONATE_C4)
	end
end

local function calculateDamage(part: BasePart, explosion: Explosion): number
	local distance = (part.Position - explosion.Position).Magnitude
	if distance > explosion.BlastRadius then
		return 0
	end

	local normalisedDistance = math.max(distance, 1)

	return 2500 / (normalisedDistance^2)
end

local function hurtAndRagdollHumanoid(part: BasePart, explosion: Explosion, distance: number)
	if not part.Parent then return end
	local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")

	if not part.Anchored then
		part:ApplyImpulse(Vector3.new(0, 1, 0) * 10) -- wheee
	end

	if not humanoid then
		return
	end

	humanoid:TakeDamage(calculateDamage(part, explosion))
	local isRagdoll = humanoid.Parent:FindFirstChild("IsRagdoll")

	task.spawn(function()
		local mappedWait = math.map(distance, 0, explosion.BlastRadius, 0, 3)

		if isRagdoll and isRagdoll:IsA("BoolValue") and humanoid.Health > 0 then
			isRagdoll.Value = true
			task.wait(mappedWait)
			isRagdoll.Value = false
		else
			humanoid.Parent:SetAttribute("Ragdoll", true)
			task.wait(mappedWait)
			humanoid.Parent:SetAttribute("Ragdoll", false)
		end
	end)
end

local function affectPartsAndHumanoidsInExplosion(explosion: Explosion): ()
	-- sounds fucking stupid i know, i have no idea what to name this function.
	-- you might be saying "but nir!!! explosion already has a .Hit event--"
	-- well, shut the hell up cuz doing it like that will still affect poor sods behind walls.
	local origin = explosion.Position
	local radius = explosion.BlastRadius
	for _, part in ipairs(workspace:GetPartBoundsInRadius(origin, radius)) do
		if part.Parent and not part.Parent:FindFirstChildOfClass("Humanoid") then
			continue
		end

		local difference = (part.Position - origin)
		local direction = difference.Unit
		local rayResult = workspace:Raycast(origin, direction * radius)
		if not rayResult or rayResult.Instance ~= part then
			--Debris:AddItem(Draw.raycast(origin, direction * radius, Color3.new(1, 0, 0)), 3)
			continue
		end
		--Debris:AddItem(Draw.line(origin, rayResult.Position, Color3.new(0.533333, 1, 0)), 3)

		-- WARNING: AWFUL HACK ALERT
		-- supposed to detonate nearby C4s
		if rayResult.Instance.Name == C4_REFERENCE_INSTANCE.Name then
			local assumedOwnerId = rayResult.Instance:GetAttribute(Attributes.OWNER)
			local playerValid = Players:GetPlayerByUserId(assumedOwnerId)
			if playerValid then
				detonateC4Proxy(playerValid, rayResult.Instance)
			end
		end

		hurtAndRagdollHumanoid(part, explosion, difference.Magnitude)
	end
end

local function createExplosion(position: Vector3): ()
	local newExplosion = Instance.new("Explosion")
	-- TODO: Add these settings to a module script
	newExplosion.Position = position
	newExplosion.ExplosionType = Enum.ExplosionType.NoCraters
	newExplosion.DestroyJointRadiusPercent = 0
	newExplosion.BlastPressure = 90000
	newExplosion.BlastRadius = 40
	newExplosion.Parent = workspace
	affectPartsAndHumanoidsInExplosion(newExplosion)
end

local function detonateC4(player: Player, c4: BasePart): ()
	if not playersPlacedC4Map[player][c4] then
		return
	end

	playersPlacedC4Map[player][c4] = nil
	c4:SetAttribute(Attributes.STATE, STATES.DETONATED)
	if c4:FindFirstChild("Armed") then
		c4.Armed:Destroy()
	end
	c4.Transparency = 1
	c4.CanCollide = false
	c4.Explode:Play()
	if c4:FindFirstChild("Attachment") then
		c4.Attachment:Destroy()
	end
	
	EntityManger.Entities[c4:GetAttribute("uuid")] = nil
	
	createExplosion(c4.Position)
	Debris:AddItem(c4, 3)
end

detonateC4Proxy = detonateC4

local function placeC4(player: Player, cframe: CFrame, target: BasePart?): ()
	local newC4 = ReplicatedStorage.ExplFolder.ExplosiveR:Clone() :: BasePart
	newC4.CFrame = cframe
	newC4:SetAttribute(Attributes.OWNER, player.UserId)
	newC4:SetAttribute(Attributes.STATE, STATES.ARMING)
	newC4:SetAttribute(Attributes.ARMING_TIMER, TIME_TO_ARM_C4)
	if target and target.Anchored == false and target:IsA("BasePart") then
		local weld = Instance.new("Weld")
		weld.Part0 = newC4
		weld.Part1 = target
		local temp = CFrame.new((newC4.Position + target.Position) * 0.5)
		weld.C0 = newC4.CFrame:Inverse() * temp
		weld.C1 = target.CFrame:Inverse() * temp
		weld.Parent = newC4
		newC4.Anchored = false
	end

	-- new entity here -----------------------------------------------------------------------------------------------------------
	newC4:SetAttribute("uuid", EntityManger.newDynamic("C4", newC4))
	
	newC4.Parent = workspace
	newC4.Place:Play()

	if not playersPlacedC4Map[player] then
		playersPlacedC4Map[player] = {}
	end

	playersPlacedC4Map[player][newC4] = true
end

local function armC4(c4: BasePart): ()
	if c4:GetAttribute(Attributes.STATE) == STATES.ARMED then
		return
	end

	c4:SetAttribute(Attributes.STATE, STATES.ARMED)
	c4.Armed:Play()
	c4.Attachment.PointLight.Enabled = true
	c4.Attachment.BillboardGui.Enabled = true
end

local function nullifyPlayersC4(player: Player): ()
	if not playersPlacedC4Map[player] then
		return
	end
	
	for c4basePart in pairs(playersPlacedC4Map[player]) do
		c4basePart:Destroy()
	end
	
	playersPlacedC4Map[player] = nil
end

local function isPlayerValid(player: Player): boolean
	if not player then
		return false
	end
	
	if not player:IsDescendantOf(Players) then
		return false
	end
	
	return true
end

PlantEvent.OnServerEvent:Connect(function(player: Player, tool: Tool, c4Cframe: CFrame, target: BasePart?)
	if tool.Handle:GetAttribute("Ammo") > 0 then
		tool.Handle:SetAttribute("Ammo", tool.Handle:GetAttribute("Ammo") - 1 )
		placeC4(player, c4Cframe, target)
	end
end)

DetonateEvent.OnServerEvent:Connect(function(player: Player)
	detonatePlayerC4s(player)
end)

RunService.Heartbeat:Connect(function(deltaTime)
	for player, c4s in pairs(playersPlacedC4Map) do
		if not isPlayerValid(player) then
			nullifyPlayersC4(player)
			continue
		end

		for c4 in pairs(c4s) do
			local currentState = c4:GetAttribute(Attributes.STATE)

			if currentState == STATES.ARMING then
				local timer = c4:GetAttribute(Attributes.ARMING_TIMER) :: number

				if timer <= 0 then
					armC4(c4)
				elseif timer > 0 then
					c4:SetAttribute(Attributes.ARMING_TIMER, timer - deltaTime)
				end

				continue
			end

			if currentState == STATES.DETONATING then
				local timer = c4:GetAttribute(Attributes.DETONATING_TIMER) :: number

				if not c4.Armed.IsPlaying then
					c4.Armed.Looped = true
					c4.Armed:Play()
				end

				if timer <= 0 then
					detonateC4(player, c4)
				elseif timer > 0 then
					c4:SetAttribute(Attributes.DETONATING_TIMER, timer - deltaTime)
				end

				continue
			end
		end
	end
end)
