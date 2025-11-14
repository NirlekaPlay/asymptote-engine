--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Door = require(ServerScriptService.server.world.level.clutter.props.Door)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)

local FUNC_TRAVERSE_FOLDERS = function(inst: Instance): boolean
	return inst:IsA("Folder")
end

local function traverse(
	root: Instance,
	traverseCondition: (Instance) -> boolean,
	callback: (Instance) -> ()
): ()
	local stack = {root}
	local index = 1

	while index > 0 do
		local current = stack[index]
		stack[index] = nil
		index = index - 1

		if current ~= root then
			callback(current)
		end

		if traverseCondition(current) then
			local children = current:GetChildren()
			for i = #children, 1, -1 do
				index = index + 1
				stack[index] = children[i]
			end
		end
	end
end

local function weld(part0: BasePart, part1: BasePart): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part1
	return weld
end

--

local ROOT = (workspace :: any).Level or (workspace :: any).DebugMission
local PROPS_FOLDER = ROOT.Props :: Folder

local RED = Color3.new(1, 0, 0)
local BLUE = Color3.new(0, 0, 1)

local doors: { [Door.Door]: true } = {}

task.wait(2)

traverse(PROPS_FOLDER, FUNC_TRAVERSE_FOLDERS, function(inst)
	if not inst:IsA("Model") or not inst.Name:find("Door") then
		return
	end

	local base = inst:FindFirstChild("Base")
	if base and base:IsA("BasePart") then
		local baseCFrame = base.CFrame
		local basePos = baseCFrame.Position
		local baseSize = base.Size
		local lookVec = baseCFrame.LookVector
		local positiveLookVec = lookVec
		local negativeLookVec = -lookVec

		local sizeZ = baseSize.Z
		local sizeX = baseSize.X

		Draw.direction(basePos, positiveLookVec, BLUE)
		Draw.direction(basePos, negativeLookVec, RED)

		-- Setup

		local frontAttatchment = Instance.new("Attachment")
		frontAttatchment.Name = "Front"
		frontAttatchment.Position = Vector3.new(0, 0, -sizeZ / 2)
		frontAttatchment.Parent = base

		local frontProxPrompt = Instance.new("ProximityPrompt")
		frontProxPrompt.Style = Enum.ProximityPromptStyle.Custom
		frontProxPrompt.Parent = frontAttatchment
	
		local backAttatchment = Instance.new("Attachment")
		backAttatchment.Name = "Back"
		backAttatchment.Position = Vector3.new(0, 0, sizeZ / 2)
		backAttatchment.Orientation = Vector3.new(0, 180, 0)
		backAttatchment.Parent = base

		local backProxPrompt = Instance.new("ProximityPrompt")
		backProxPrompt.Style = Enum.ProximityPromptStyle.Custom
		backProxPrompt.Parent = backAttatchment

		local middleAttatchment = Instance.new("Attachment")
		middleAttatchment:SetAttribute("OmniDir", true)
		middleAttatchment.Parent = base

		local middleProxPrompt = Instance.new("ProximityPrompt")
		middleProxPrompt.Style = Enum.ProximityPromptStyle.Custom
		middleProxPrompt.Parent = middleAttatchment

		local hingeAttatchment = Instance.new("Attachment")
		hingeAttatchment.Name = "Hinge"
		hingeAttatchment.Position = Vector3.new(sizeX / 2, 0, 0)
		hingeAttatchment.Parent = base

		local hingePart = Instance.new("Part")
		hingePart.Name = "HingePart"
		hingePart.Position = hingeAttatchment.WorldPosition
		hingePart.Size = Vector3.one
		hingePart.Transparency = 1
		hingePart.CanCollide = false
		hingePart.CanQuery = false
		hingePart.AudioCanCollide = false
		hingePart.Anchored = true
		hingePart.Parent = inst

		-- TODO: This is too hardcoded on Part0 and Handle

		local part0 = inst:FindFirstChild("Part0") :: BasePart
		local handle = inst:FindFirstChild("Handle") :: BasePart

		base.CanCollide = false

		part0.Anchored = false
		handle.Anchored = false

		weld(part0, hingePart)
		weld(handle, hingePart)

		-- Setup

		local newDoor = Door.new(hingePart)
		doors[newDoor] = true

		-- Connections

		frontProxPrompt.Triggered:Connect(function(player)
			print("Prox prompt front triggered")
			newDoor:onPromptTriggered(Door.Sides.FRONT)
			if newDoor.state == Door.States.OPENING then
				part0.CanCollide = false
				handle.CanCollide = false
			else
				part0.CanCollide = true
				handle.CanCollide = true
			end
		end)

		backProxPrompt.Triggered:Connect(function(player)
			print("Prox prompt back triggered")
			newDoor:onPromptTriggered(Door.Sides.BACK)
			if newDoor.state == Door.States.OPENING then
				part0.CanCollide = false
				handle.CanCollide = false
			else
				part0.CanCollide = true
				handle.CanCollide = true
			end
		end)

		middleProxPrompt.Triggered:Connect(function(player)
			print("Prox prompt middle triggered")
			newDoor:onPromptTriggered(Door.Sides.MIDDLE)
			if newDoor.state == Door.States.OPENING then
				part0.CanCollide = false
				handle.CanCollide = false
			else
				part0.CanCollide = true
				handle.CanCollide = true
			end
		end)
	end
end)

RunService.PostSimulation:Connect(function(deltaTime)
	for doorObj in doors do
		doorObj:update(deltaTime)
	end
end)
