--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainDebugPayload = require(ReplicatedStorage.shared.network.BrainDebugPayload)

local currentCamera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local entityByUuid: { [string]: Model } = {}
local brainDumpsPerEntity: { [string]: BrainDebugPayload.BrainDump } = {}
local uiObjectsPerEntity: { [string]: BrainDumpGuiObjects } = {}
local lastLookedAtEntityUuid: string? = nil
local brainDebugScreenGui: ScreenGui

local SCREENGUI_NAME = "DebugBrain"
local MEMORIES_TEXT_COLOR = Color3.fromRGB(204, 204, 204)
local ACTIVITIES_TEXT_COLOR = Color3.new(0, 1, 0)
local BEHAVIORS_TEXT_COLOR = Color3.new(0, 1, 1)
local HEALTH_TEXT_COLOR = Color3.new(1, 1, 1)
local NAME_TEXT_COLOR = Color3.new(1, 1, 1)
local MAX_RENDER_DIST_FOR_BRAIN_INFO = 30
local MAX_TARGETING_DIST = 8
local TEXT_SCALE = 0.025
local LARGE_TEXT_SCALE = 0.035
local LAYOUT_ORDERS = {
	MEMORIES_START = 100,
	ACTIVITIES_START = 200,
	BEHAVIORS_START = 300,
	HEALTH = 400,
	NAME = 500
}

--[=[
	@class BrainDebugRenderer

	Displays a BillboardGui detailing Agents' brain system.
	This includes, in order of appearance, memories, activites,
	behaviors, health, and name.
]=]
local BrainDebugRenderer = {}

export type BrainDumpGuiObjects = {
	billboard: BillboardGui,
	nameTextLabel: TextLabel,
	healthTextLabel: TextLabel,
	memoriesTextLabels: { [string]: TextLabel },
	activitiesTextLabels: { [string]: TextLabel },
	behaviorsTextLabels: { [string]: TextLabel },
}

function BrainDebugRenderer.addOrUpdateBrainDump(brainDump: BrainDebugPayload.BrainDump): ()
	entityByUuid[brainDump.uuid] = brainDump.character
	brainDumpsPerEntity[brainDump.uuid] = brainDump
end

function BrainDebugRenderer.clear(): ()
	table.clear(brainDumpsPerEntity)
	table.clear(entityByUuid)
	BrainDebugRenderer.destroyAllUis()
	lastLookedAtEntityUuid = nil
end

--

function BrainDebugRenderer.render()
	BrainDebugRenderer.clearRemovedEntities()
	BrainDebugRenderer.doRender()
	BrainDebugRenderer.updateLastLookedAtCharacter()
end

function BrainDebugRenderer.clearRemovedEntities(): ()
	for uuid in pairs(brainDumpsPerEntity) do
		local character = entityByUuid[uuid]
		if not character:IsDescendantOf(workspace) then
			BrainDebugRenderer.cleanUpEntity(uuid)
			continue
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			BrainDebugRenderer.cleanUpEntity(uuid)
			continue
		end

		if humanoid.Health <= 0 then
			BrainDebugRenderer.cleanUpEntity(uuid)
			continue
		end
	end
end

function BrainDebugRenderer.cleanUpEntity(uuid: string): ()
	brainDumpsPerEntity[uuid] = nil
	if uiObjectsPerEntity[uuid] and uiObjectsPerEntity[uuid].billboard then
		uiObjectsPerEntity[uuid].billboard:Destroy()
	end
	uiObjectsPerEntity[uuid] = nil
	entityByUuid[uuid] = nil
end

function BrainDebugRenderer.destroyAllUis(): ()
	for _, uiObjects in pairs(uiObjectsPerEntity) do
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
	local uiObjects = uiObjectsPerEntity[brainDump.uuid] :: BrainDumpGuiObjects
	if not uiObjects then
		local newUiObjects = {}
		newUiObjects.billboard = BrainDebugRenderer.createNewBrainDumpBillboard(brainDump)
		newUiObjects.nameTextLabel = nil :: TextLabel?
		newUiObjects.healthTextLabel = nil :: TextLabel?
		newUiObjects.memoriesTextLabels = {}
		newUiObjects.activitiesTextLabels = {}
		newUiObjects.behaviorsTextLabels = {}
		uiObjectsPerEntity[brainDump.uuid] = newUiObjects
		uiObjects = newUiObjects
	end

	if not uiObjects.nameTextLabel then
		uiObjects.nameTextLabel = BrainDebugRenderer.createNewTextLabel(
			"",
			LAYOUT_ORDERS.NAME,
			NAME_TEXT_COLOR,
			LARGE_TEXT_SCALE,
			brainDump.name,
			uiObjects.billboard
		)
		uiObjects.nameTextLabel.Visible = true
		uiObjects.nameTextLabel.Text = brainDump.name
	end

	if not uiObjects.healthTextLabel then
		uiObjects.healthTextLabel = BrainDebugRenderer.createNewTextLabel(
			"",
			LAYOUT_ORDERS.HEALTH,
			HEALTH_TEXT_COLOR,
			TEXT_SCALE,
			brainDump.name,
			uiObjects.billboard
		)
	end
	uiObjects.healthTextLabel.Visible = isSelected
	uiObjects.healthTextLabel.Text = `health: {brainDump.health} / {brainDump.maxHealth}`

	-- handle memories (already alphabetically sorted from server)
	local memoriesMap = {}
	for memoryIndex, memory in pairs(brainDump.memories) do
		local memoryType = string.split(memory, ":")[1]
		memoriesMap[memoryType] = true

		if not uiObjects.memoriesTextLabels[memoryType] then
			local newMemoryTextLabel = BrainDebugRenderer.createNewTextLabel(
				"",
				LAYOUT_ORDERS.MEMORIES_START + memoryIndex,
				MEMORIES_TEXT_COLOR,
				TEXT_SCALE,
				memory,
				uiObjects.billboard
			)
			newMemoryTextLabel.Visible = isSelected
			uiObjects.memoriesTextLabels[memoryType] = newMemoryTextLabel
		end
		uiObjects.memoriesTextLabels[memoryType].Text = memory
		uiObjects.memoriesTextLabels[memoryType].LayoutOrder = LAYOUT_ORDERS.MEMORIES_START + memoryIndex
		uiObjects.memoriesTextLabels[memoryType].Visible = isSelected
	end

	for memory in pairs(uiObjects.memoriesTextLabels) do
		uiObjects.memoriesTextLabels[memory].Visible = isSelected

		if not memoriesMap[memory] then
			uiObjects.memoriesTextLabels[memory]:Destroy()
			uiObjects.memoriesTextLabels[memory] = nil
		end
	end

	-- activities
	-- idk what order these are gonna be in.
	local activitiesMap = {}
	for activityIndex, activity in pairs(brainDump.activites) do
		activitiesMap[activity] = true

		if not uiObjects.activitiesTextLabels[activity] then
			local newMemoryTextLabel = BrainDebugRenderer.createNewTextLabel(
				"",
				LAYOUT_ORDERS.MEMORIES_START + activityIndex,
				ACTIVITIES_TEXT_COLOR,
				TEXT_SCALE,
				activity,
				uiObjects.billboard
			)
			newMemoryTextLabel.Visible = isSelected
			uiObjects.activitiesTextLabels[activity] = newMemoryTextLabel
		end
		uiObjects.activitiesTextLabels[activity].Text = activity
		uiObjects.activitiesTextLabels[activity].LayoutOrder = LAYOUT_ORDERS.ACTIVITIES_START + activityIndex
		uiObjects.activitiesTextLabels[activity].Visible = isSelected
	end

	for activity in pairs(uiObjects.activitiesTextLabels) do
		uiObjects.activitiesTextLabels[activity].Visible = isSelected

		if not activitiesMap[activity] then
			uiObjects.activitiesTextLabels[activity]:Destroy()
			uiObjects.activitiesTextLabels[activity] = nil
		end
	end

	-- behaviors
	local behaviorsMap = {}
	for behaviorIndex, behavior in pairs(brainDump.behaviors) do
		behaviorsMap[behavior] = true

		if not uiObjects.behaviorsTextLabels[behavior] then
			local newMemoryTextLabel = BrainDebugRenderer.createNewTextLabel(
				"",
				LAYOUT_ORDERS.MEMORIES_START + behaviorIndex,
				BEHAVIORS_TEXT_COLOR,
				TEXT_SCALE,
				behavior,
				uiObjects.billboard
			)
			newMemoryTextLabel.Visible = isSelected
			uiObjects.behaviorsTextLabels[behavior] = newMemoryTextLabel
		end
		uiObjects.behaviorsTextLabels[behavior].Text = behavior
		uiObjects.behaviorsTextLabels[behavior].LayoutOrder = LAYOUT_ORDERS.BEHAVIORS_START + behaviorIndex
		uiObjects.behaviorsTextLabels[behavior].Visible = isSelected
	end

	for behavior in pairs(uiObjects.behaviorsTextLabels) do
		uiObjects.behaviorsTextLabels[behavior].Visible = isSelected

		if not behaviorsMap[behavior] then
			uiObjects.behaviorsTextLabels[behavior]:Destroy()
			uiObjects.behaviorsTextLabels[behavior] = nil
		end
	end
end

function BrainDebugRenderer.updateLastLookedAtCharacter(): ()
	local currentMouseTarget = mouse.Target :: BasePart?

	if not currentMouseTarget then
		return
	end

	for uuid, brainDump in pairs(brainDumpsPerEntity) do
		local character = entityByUuid[uuid]
		if currentMouseTarget:IsDescendantOf(character) then
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
	local npcPrimaryPart = brainDump.character.PrimaryPart
	if not npcPrimaryPart then
		return false
	end

	local playerPos = currentCamera.CFrame.Position
	local npcPosition = npcPrimaryPart.Position
	local difference = (npcPosition - playerPos).Magnitude

	return difference <= MAX_RENDER_DIST_FOR_BRAIN_INFO
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

function BrainDebugRenderer.createNewTextLabel(
	name: string, layoutOrder: number, textColor: Color3, textScale: number, text: string, parent: Instance
): TextLabel
	local newTextLabel = Instance.new("TextLabel")
	newTextLabel.BackgroundTransparency = 1
	newTextLabel.LayoutOrder = layoutOrder
	newTextLabel.AutomaticSize = Enum.AutomaticSize.X
	newTextLabel.Name = name
	newTextLabel.Text = text
	newTextLabel.Size = UDim2.fromScale(1, textScale)
	newTextLabel.FontFace = Font.fromName("RobotoMono")
	newTextLabel.TextColor3 = textColor
	newTextLabel.TextScaled = true
	newTextLabel.TextXAlignment = Enum.TextXAlignment.Left
	newTextLabel.TextYAlignment = Enum.TextYAlignment.Top
	newTextLabel.Visible = false
	newTextLabel.Parent = parent

	return newTextLabel
end

function BrainDebugRenderer.createNewBrainDumpBillboard(brainDump: BrainDebugPayload.BrainDump): BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.ExtentsOffset = Vector3.new(0, 7, 0)
	billboardGui.MaxDistance = MAX_RENDER_DIST_FOR_BRAIN_INFO * 2
	billboardGui.Adornee = brainDump.character.PrimaryPart :: BasePart
	billboardGui.LightInfluence = 0
	billboardGui.ClipsDescendants = false
	billboardGui.AlwaysOnTop = true
	billboardGui.ResetOnSpawn = false
	billboardGui.Name = brainDump.name
	billboardGui.Size = UDim2.fromScale(40, 40)
	billboardGui.StudsOffset = Vector3.new(20, 17, 0)

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.FillDirection = Enum.FillDirection.Vertical
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	uiListLayout.Parent = billboardGui

	billboardGui.Parent = brainDebugScreenGui

	return billboardGui
end

return BrainDebugRenderer