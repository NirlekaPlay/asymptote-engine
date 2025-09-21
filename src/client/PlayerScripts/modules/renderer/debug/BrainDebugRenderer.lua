--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugRenderer = require(script.Parent.DebugRenderer)
local BrainDebugPayload = require(ReplicatedStorage.shared.network.payloads.BrainDebugPayload)

local currentCamera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local entityByUuid: { [string]: Model } = {}
local brainDumpsPerEntity: { [string]: BrainDebugPayload.BrainDump } = {}
local lastLookedAtEntityUuid: string? = nil

local SHOW_NAME_FOR_ALL = true
local SHOW_HEALTH_FOR_ALL = false
local SHOW_DETECTED_STATUSES_FOR_ALL = false
local SHOW_SUSPICION_LEVELS_FOR_ALL = false
local SHOW_BEHAVIORS_FOR_ALL = false
local SHOW_ACTIVITIES_FOR_ALL = false
local SHOW_MEMORIES_FOR_ALL = false
local SHOW_NAME_FOR_SELECTED = true
local SHOW_HEALTH_FOR_SELECTED = true
local SHOW_DETECTED_STATUSES_FOR_SELECTED = true
local SHOW_SUSPICION_LEVELS_FOR_SELECTED = true
local SHOW_BEHAVIORS_FOR_SELECTED = true
local SHOW_ACTIVITIES_FOR_SELECTED = true
local SHOW_MEMORIES_FOR_SELECTED = true
local MAX_RENDER_DIST_FOR_BRAIN_INFO = 120
local MAX_TARGETING_DIST = 32
local TEXT_SCALE = 1
local LARGE_TEXT_SCALE = 1.5
local CYAN = Color3.new(0, 1, 1)
local GRAY = Color3.new(0.8, 0.8, 0.8)
local GREEN = Color3.new(0, 1, 0)
local ORANGE = Color3.new(1, 0.647059, 0)
local RED = Color3.new(1, 0, 0)
local WHITE = Color3.new(1, 1, 1)

--[=[
	@class BrainDebugRenderer

	Displays a BillboardGui detailing Agents' brain system.
	This includes, in order of appearance from top to bottom,
	memories, activities, behaviors, health, and name.
]=]
local BrainDebugRenderer = {}

function BrainDebugRenderer.addOrUpdateBrainDump(brainDump: BrainDebugPayload.BrainDump): ()
	entityByUuid[brainDump.uuid] = brainDump.character
	brainDumpsPerEntity[brainDump.uuid] = brainDump
end

function BrainDebugRenderer.clear(): ()
	table.clear(brainDumpsPerEntity)
	table.clear(entityByUuid)
	lastLookedAtEntityUuid = nil
end

--

function BrainDebugRenderer.render()
	BrainDebugRenderer.clearRemovedEntities()
	BrainDebugRenderer.doRender()
	BrainDebugRenderer.updateLastLookedAtCharacter()
end

function BrainDebugRenderer.clearRemovedEntities(): ()
	for uuid, brainDump in pairs(brainDumpsPerEntity) do
		if BrainDebugRenderer.isNpcInvalid(brainDump) then
			BrainDebugRenderer.cleanUpEntity(uuid)
		end
	end
end

function BrainDebugRenderer.cleanUpEntity(uuid: string): ()
	brainDumpsPerEntity[uuid] = nil
	entityByUuid[uuid] = nil
end

function BrainDebugRenderer.doRender(): ()
	for _, brainDump in pairs(brainDumpsPerEntity) do
		if BrainDebugRenderer.isPlayerCloseEnoughToNpc(brainDump) then
			BrainDebugRenderer.renderBrainInfo(brainDump)
		end
	end
end

function BrainDebugRenderer.renderBrainInfo(brainDump: BrainDebugPayload.BrainDump): ()
	local charPos = (brainDump.character.PrimaryPart :: BasePart).Position
	local isSelected = BrainDebugRenderer.isNpcSelected(brainDump)
	local i = 0

	BrainDebugRenderer.renderTextOverCharacter(
		brainDump.name, charPos, i, WHITE, LARGE_TEXT_SCALE
	)
	i += 1

	if isSelected then
		local healthColor: Color3
		if brainDump.health < brainDump.maxHealth then
			-- make it piss yellow.
			-- because gamers always piss themselves when their health is below 100.
			healthColor = ORANGE
		else
			healthColor = WHITE
		end

		BrainDebugRenderer.renderTextOverCharacter(
			`health: {string.format("%.1f", brainDump.health)} / {string.format("%.1f", brainDump.maxHealth)}`, charPos, i, healthColor, TEXT_SCALE
		)
		i += 1
	end

	if isSelected then
		-- traverse in reverse,
		-- so higer priority statuses are on top
		for index = #brainDump.detectedStatuses, 1, -1 do
			local detectedStatus = brainDump.detectedStatuses[index]
			BrainDebugRenderer.renderTextOverCharacter(
				detectedStatus, charPos, i, RED, TEXT_SCALE
			)
			i += 1
		end
	end

	if isSelected then
		for _, suspicionLevel in ipairs(brainDump.suspicionLevels) do
			BrainDebugRenderer.renderTextOverCharacter(
				suspicionLevel, charPos, i, ORANGE, TEXT_SCALE
			)
			i += 1
		end
	end

	if isSelected then
		for _, behavior in ipairs(brainDump.behaviors) do
			BrainDebugRenderer.renderTextOverCharacter(
				behavior, charPos, i, CYAN, TEXT_SCALE
			)
			i += 1
		end
	end

	if isSelected then
		for _, activity in ipairs(brainDump.activites) do
			BrainDebugRenderer.renderTextOverCharacter(
				activity, charPos, i, GREEN, TEXT_SCALE
			)
			i += 1
		end
	end

	if isSelected then
		-- traverse it in reverse.
		-- due to the way it is sorted alphabetically from the server,
		-- it will appear A-Z from bottom to top, instead of top to bottom
		for index = #brainDump.memories, 1, -1 do
			local memory = brainDump.memories[index]
			BrainDebugRenderer.renderTextOverCharacter(
				memory, charPos, i, GRAY, TEXT_SCALE
			)
			i += 1
		end
	end
end

function BrainDebugRenderer.renderTextOverCharacter(
	text: string,
	charPos: Vector3,
	lineIndex: number,
	color: Color3, 
	textScale: number
): ()

	local worldPos = Vector3.new(
		charPos.X,
		charPos.Y + 2.4 + (lineIndex * 1.5),
		charPos.Z
	)
	
	DebugRenderer.renderFloatingText(text, worldPos, color, textScale, false, 0, true)
end

function BrainDebugRenderer.updateLastLookedAtCharacter(): ()
	local playerPos = currentCamera.CFrame.Position
	local currentMouseTarget = mouse.Target :: BasePart?

	if not currentMouseTarget then
		return
	end

	for uuid, brainDump in pairs(brainDumpsPerEntity) do
		local character = entityByUuid[uuid]
		if not currentMouseTarget:IsDescendantOf(character) then
			continue
		end

		local distance = (currentMouseTarget.Position - playerPos).Magnitude
		if distance > MAX_TARGETING_DIST then
			continue
		end

		lastLookedAtEntityUuid = brainDump.uuid
		break
	end
end

--

function BrainDebugRenderer.isNpcInvalid(brainDump: BrainDebugPayload.BrainDump): boolean
	local character = entityByUuid[brainDump.uuid]
	if not character then
		return true
	end

	if not character:IsDescendantOf(workspace) then
		return true
	end

	if not character.PrimaryPart then
		return true
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return true
	end

	if humanoid.Health <= 0 then
		return true
	end

	return false
end

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

return BrainDebugRenderer