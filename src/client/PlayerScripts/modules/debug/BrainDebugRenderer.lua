--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainDebugPayload = require(ReplicatedStorage.shared.network.BrainDebugPayload)

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local brainDumpsPerEntity: { [Model]: BrainDebugPayload.BrainDump } = {}
local uiObjectsPerEntity: { [Model]: BrainDumpGuiObjects } = {}
local lastLookedAtEntity: Model? = nil
local lastLookedAtEntityUuid: number? = nil
local brainDebugScreenGui: ScreenGui

local SCREENGUI_NAME = "BrainDebug"
local MEMORIES_TEXT_COLOR = Color3.new(0.9, 0.9, 0.9)
local ACTIVITIES_TEXT_COLOR = Color3.new(0.3, 1, 0)
local BEHAVIORS_TEXT_COLOR = Color3.new(0, 1, 1)
local HEALTH_TEXT_COLOR = Color3.new(1, 1, 1)
local NAME_TEXT_COLOR = Color3.new(1, 1, 1)
local LAYOUT_ORDERS = {
	MEMORIES_START = 100,
	ACTIVITIES_START = 200,
	BEHAVIORS_START = 300,
	HEALTH = 400,
	NAME = 500
}
--
local MIN_DISTANCE_TO_UPDATE_GUI = 30


--[=[
	@class BrainDebugRenderer

	Displays a BillboardGui detailing Agents' brain system.
	This includes, in order of appearance, memories, activites,
	behaviors, health, and name.
]=]
local BrainDebugRenderer = {}
local self = BrainDebugRenderer

export type BrainDebugRenderer = typeof(BrainDebugRenderer)
export type BrainDumpGuiObjects = {
	billboard: BillboardGui,
	textlabelReference: TextLabel,
	nameTextLabel: TextLabel,
	healthTextLabel: TextLabel,
	memoriesTextLabels: { [string]: TextLabel },
	activitesTextLabels: { [string]: TextLabel },
	behaviorsTextLabels: { [string]: TextLabel },
}

function BrainDebugRenderer.addOrUpdateBrainDump(brainDump: BrainDebugPayload.BrainDump): ()
	brainDumpsPerEntity[brainDump.character] = brainDump
end

function BrainDebugRenderer.clear(): ()
	table.clear(brainDumpsPerEntity)
	BrainDebugRenderer.destroyAllUis()
	lastLookedAtEntity = nil
	lastLookedAtEntityUuid = nil
end

--

function BrainDebugRenderer.render()
	self.clearRemovedEntities()
	self.destroyUiForRemovedEntities()
	self.doRender()
	self.updateLastLookedAtCharacter()
end

function BrainDebugRenderer.clearRemovedEntities(): ()
	for character in pairs(brainDumpsPerEntity) do
		if not character:IsDescendantOf(workspace) then
			brainDumpsPerEntity[character] = nil
			continue
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			brainDumpsPerEntity[character] = nil
			continue
		end

		if humanoid.Health <= 0 then
			brainDumpsPerEntity[character] = nil
			continue
		end
	end
end

function BrainDebugRenderer.destroyUiForRemovedEntities(): ()
	for character, uiObjects in pairs(uiObjectsPerEntity) do
		if not brainDumpsPerEntity[character] then
			uiObjects.billboard:Destroy()
			uiObjectsPerEntity[character] = nil
		end
	end
end

function BrainDebugRenderer.destroyAllUis(): ()
	for character, uiObjects in pairs(uiObjectsPerEntity) do
		uiObjects.billboard:Destroy()
	end
	
	table.clear(uiObjectsPerEntity)
end

function BrainDebugRenderer.doRender(): ()
	if not brainDebugScreenGui then
		brainDebugScreenGui = BrainDebugRenderer.createNewScreenGui()
	end

	for _, brainDump in pairs(brainDumpsPerEntity) do
		if BrainDebugRenderer.isPlayerCloseEnoughToNpc(brainDump) then
			BrainDebugRenderer.renderBrainInfo(brainDump)
		end
	end
end

function BrainDebugRenderer.renderBrainInfo(brainDump: BrainDebugPayload.BrainDump): ()
	local isSelected = BrainDebugRenderer.isNpcSelected(brainDump)

	if not uiObjectsPerEntity[brainDump.character] then
		local newBillboard, referenceTextLabel = BrainDebugRenderer.createNewBrainDumpBillboard(brainDump)
		newBillboard.Parent = brainDebugScreenGui

		local frame = newBillboard:FindFirstChild("Frame") :: Frame
		
		-- health
		local newHealthTextLabel = referenceTextLabel:Clone()
		newHealthTextLabel.LayoutOrder = LAYOUT_ORDERS.HEALTH
		newHealthTextLabel.TextColor3 = HEALTH_TEXT_COLOR
		newHealthTextLabel.Name = "health"
		newHealthTextLabel.Parent = frame
		
		-- name
		local newNameTextLabel = referenceTextLabel:Clone()
		newNameTextLabel.LayoutOrder = LAYOUT_ORDERS.NAME
		newNameTextLabel.TextColor3 = NAME_TEXT_COLOR
		newNameTextLabel.Name = "name"
		newNameTextLabel.Size = UDim2.fromScale(1, 0.035)
		newNameTextLabel.Visible = true
		newNameTextLabel.Parent = frame

		local newUiObject: BrainDumpGuiObjects = {
			billboard = newBillboard,
			textlabelReference = referenceTextLabel,
			healthTextLabel = newHealthTextLabel,
			nameTextLabel = newNameTextLabel,
			memoriesTextLabels = {},
			activitesTextLabels = {},
			behaviorsTextLabels = {}
		}

		uiObjectsPerEntity[brainDump.character] = newUiObject
	end

	local currentUiObject = uiObjectsPerEntity[brainDump.character]
	if not currentUiObject.billboard.Adornee then
		currentUiObject.billboard.Adornee = brainDump.character:FindFirstChild("Head") :: BasePart
	end

	currentUiObject.nameTextLabel.Text = brainDump.name
	currentUiObject.healthTextLabel.Visible = isSelected
	if isSelected then
		currentUiObject.healthTextLabel.Text = `health: {brainDump.health} / {brainDump.maxHealth}`
	end

	-- handle memories (already alphabetically sorted from server)
	local memoriesMap = {}
	for memoryIndex, memory in pairs(brainDump.memories) do
		memoriesMap[memory] = true

		if not currentUiObject.memoriesTextLabels[memory] then
			local newMemoryTextLabel = currentUiObject.textlabelReference:Clone()
			newMemoryTextLabel.Name = "memory_" .. memory
			newMemoryTextLabel.LayoutOrder = LAYOUT_ORDERS.MEMORIES_START + memoryIndex
			newMemoryTextLabel.TextColor3 = MEMORIES_TEXT_COLOR
			newMemoryTextLabel.Text = memory
			newMemoryTextLabel.Visible = isSelected
			newMemoryTextLabel.Parent = currentUiObject.billboard.Frame
			currentUiObject.memoriesTextLabels[memory] = newMemoryTextLabel
		end
	end

	for memory in pairs(currentUiObject.memoriesTextLabels) do
		currentUiObject.memoriesTextLabels[memory].Visible = isSelected

		if not memoriesMap[memory] then
			currentUiObject.memoriesTextLabels[memory]:Destroy()
			currentUiObject.memoriesTextLabels[memory] = nil
		end
	end

	local activitiesArray = {}
	for activity in pairs(brainDump.activites) do
		table.insert(activitiesArray, activity)
	end
	table.sort(activitiesArray)
	
	local activitiesMap = {}
	for activityIndex, activity in ipairs(activitiesArray) do
		activitiesMap[activity] = true
		
		if not currentUiObject.activitesTextLabels[activity] then
			local newActivityTextLabel = currentUiObject.textlabelReference:Clone()
			newActivityTextLabel.Name = "activity_" .. activity
			newActivityTextLabel.LayoutOrder = LAYOUT_ORDERS.ACTIVITIES_START + activityIndex
			newActivityTextLabel.TextColor3 = ACTIVITIES_TEXT_COLOR
			newActivityTextLabel.Text = activity
			newActivityTextLabel.Visible = isSelected
			newActivityTextLabel.Parent = currentUiObject.billboard.Frame
			currentUiObject.activitesTextLabels[activity] = newActivityTextLabel
		else
			local activityTextLabel = currentUiObject.activitesTextLabels[activity]
			activityTextLabel.LayoutOrder = LAYOUT_ORDERS.ACTIVITIES_START + activityIndex
		end
	end

	for activity in pairs(currentUiObject.activitesTextLabels) do
		currentUiObject.activitesTextLabels[activity].Visible = isSelected

		if not activitiesMap[activity] then
			currentUiObject.activitesTextLabels[activity]:Destroy()
			currentUiObject.activitesTextLabels[activity] = nil
		end
	end

	local behaviorsArray = {}
	for behavior in pairs(brainDump.behaviors) do
		table.insert(behaviorsArray, behavior)
	end
	table.sort(behaviorsArray)
	
	local behaviorsMap = {}
	for behaviorIndex, behavior in ipairs(behaviorsArray) do
		behaviorsMap[behavior] = true
		
		if not currentUiObject.behaviorsTextLabels[behavior] then
			local newBehaviorTextLabel = currentUiObject.textlabelReference:Clone()
			newBehaviorTextLabel.Name = "behavior_" .. behavior
			newBehaviorTextLabel.LayoutOrder = LAYOUT_ORDERS.BEHAVIORS_START + behaviorIndex
			newBehaviorTextLabel.TextColor3 = BEHAVIORS_TEXT_COLOR
			newBehaviorTextLabel.Text = behavior
			newBehaviorTextLabel.Parent = currentUiObject.billboard.Frame
			currentUiObject.behaviorsTextLabels[behavior] = newBehaviorTextLabel
		else
			local behaviorTextLabel = currentUiObject.behaviorsTextLabels[behavior]
			behaviorTextLabel.LayoutOrder = LAYOUT_ORDERS.BEHAVIORS_START + behaviorIndex
		end
	end

	for behavior in pairs(currentUiObject.behaviorsTextLabels) do
		currentUiObject.behaviorsTextLabels[behavior].Visible = isSelected

		if not behaviorsMap[behavior] then
			currentUiObject.behaviorsTextLabels[behavior]:Destroy()
			currentUiObject.behaviorsTextLabels[behavior] = nil
		end
	end
end

function BrainDebugRenderer.updateLastLookedAtCharacter(): ()
	local currentMouseTarget = mouse.Target :: BasePart?

	if not currentMouseTarget then
		return
	end

	for character, brainDump in pairs(brainDumpsPerEntity) do
		if currentMouseTarget:IsDescendantOf(character) then
			lastLookedAtEntity = character
			lastLookedAtEntityUuid = brainDump.uuid
			break
		end
	end
end

--

function BrainDebugRenderer.isNpcSelected(brainDump: BrainDebugPayload.BrainDump): boolean
	return lastLookedAtEntityUuid == brainDump.uuid
end

function BrainDebugRenderer.isPlayerCloseEnoughToNpc(brainDump: BrainDebugPayload.BrainDump): boolean
	local character = localPlayer.Character
	if not character then
		return false
	end

	local primaryPart = character.PrimaryPart
	if not primaryPart then
		return false
	end

	local npcPrimaryPart = brainDump.character.PrimaryPart
	if not npcPrimaryPart then
		return false
	end

	local playerPos = primaryPart.Position
	local npcPosition = npcPrimaryPart.Position
	local difference = (npcPosition - playerPos).Magnitude

	return difference <= MIN_DISTANCE_TO_UPDATE_GUI
end

--

function BrainDebugRenderer.createNewScreenGui(): ScreenGui
	local newScreenGui = Instance.new("ScreenGui")
	newScreenGui.Name = SCREENGUI_NAME
	newScreenGui.IgnoreGuiInset = true
	newScreenGui.ResetOnSpawn = false
	newScreenGui.Parent = localPlayer.PlayerGui

	return newScreenGui
end

function BrainDebugRenderer.createNewBrainDumpBillboard(brainDump: BrainDebugPayload.BrainDump): (BillboardGui, TextLabel)
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.ExtentsOffset = Vector3.new(0, 7, 0)
	billboardGui.LightInfluence = 0
	billboardGui.ClipsDescendants = false
	billboardGui.AlwaysOnTop = true
	billboardGui.ResetOnSpawn = false
	billboardGui.Name = brainDump.name
	billboardGui.Size = UDim2.fromScale(40, 40)
	billboardGui.StudsOffset = Vector3.new(20, 17, 0)

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.ClipsDescendants = false
	frame.BackgroundTransparency = 1
	frame.Parent = billboardGui

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.FillDirection = Enum.FillDirection.Vertical
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	uiListLayout.Parent = frame

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.AutomaticSize = Enum.AutomaticSize.X
	textLabel.Name = "REFERENCE"
	textLabel.Size = UDim2.fromScale(1, 0.025)
	textLabel.FontFace = Font.fromName("RobotoMono")
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.Visible = false
	textLabel.Parent = frame

	return billboardGui, textLabel
end

return BrainDebugRenderer