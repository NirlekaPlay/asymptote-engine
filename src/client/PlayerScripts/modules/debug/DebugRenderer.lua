--!strict

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local debugRenderersMap: { [SimpleDebugRenderer]: true } = {}
local debugRendererScreenGui: ScreenGui

--[=[
	@class DebugRenderer

	Renders debug data. All render calls from DebugRenderers are batched until
	the end of the render update cycle, where all render calls are rendered
	on screen.

	That rendered data will not persist if theres not another render call on
	the next frame.
]=]
local DebugRenderer = {}

export type SimpleDebugRenderer = {
	clear: () -> (),
	render: () -> ()
}

type FloatingTextData = {
	text: string,
	worldPos: Vector3,
	color: Color3,
	textScale: number,
	centered: boolean,
	xOffset: number,
	alwaysOnTop: boolean
}

type FloatingTextObject = {
	part: Part,
	textLabel: TextLabel,
	billboardGui: BillboardGui,
	inUse: boolean
}

local queuedFloatingTexts: { FloatingTextData } = {}
local floatingTextPool: { FloatingTextObject } = {}

local function getFloatingTextObject(): FloatingTextObject
	for _, obj in ipairs(floatingTextPool) do
		if not obj.inUse then
			obj.inUse = true
			obj.billboardGui.Enabled = true
			return obj
		end
	end

	local newObj = DebugRenderer.createFloatingTextObject()
	newObj.inUse = true
	table.insert(floatingTextPool, newObj)
	return newObj
end

local function resetUnusedObjects()
	for _, obj in ipairs(floatingTextPool) do
		if not obj.inUse then
			obj.billboardGui.Enabled = false
		end
		obj.inUse = false
	end
end

function DebugRenderer.addSimpleDebugRenderer(renderer: SimpleDebugRenderer): ()
	debugRenderersMap[renderer] = true
end

function DebugRenderer.removeSimpleDebugRenderer(renderer: SimpleDebugRenderer): ()
	debugRenderersMap[renderer] = nil
end

function DebugRenderer.clear(): ()
	if debugRendererScreenGui then
		debugRendererScreenGui.Enabled = false
	end

	for debugRenderer in pairs(debugRenderersMap) do
		debugRenderer.clear()
	end
	
	table.clear(queuedFloatingTexts)
end

function DebugRenderer.render(): ()
	if not debugRendererScreenGui then
		debugRendererScreenGui = DebugRenderer.createScreenGui()
	end

	table.clear(queuedFloatingTexts)

	for debugRenderer in pairs(debugRenderersMap) do
		debugRenderer.render()
	end

	DebugRenderer.renderBatchedTexts()
end

function DebugRenderer.renderFloatingText(
	text: string,
	worldPos: Vector3,
	color: Color3,
	textScale: number,
	centered: boolean,
	xOffset: number,
	alwaysOnTop: boolean
): ()
	local textData: FloatingTextData = {
		text = text,
		worldPos = worldPos,
		color = color,
		textScale = textScale,
		centered = centered,
		xOffset = xOffset,
		alwaysOnTop = alwaysOnTop
	}
	
	table.insert(queuedFloatingTexts, textData)
end

function DebugRenderer.renderBatchedTexts(): ()
	resetUnusedObjects()

	for _, textData in ipairs(queuedFloatingTexts) do
		local textObj = getFloatingTextObject()
		DebugRenderer.updateFloatingTextObject(textObj, textData)
		--[[local textShit = DebugRenderer.createFloatingTextObject()
		DebugRenderer.updateFloatingTextObject(textShit, textData)
		Debris:AddItem(textShit.part, 0.1)
		Debris:AddItem(textShit.billboardGui, 0.1)]]
	end
end

function DebugRenderer.updateFloatingTextObject(
	floatingTextObj: FloatingTextObject, 
	textData: FloatingTextData
): ()

	floatingTextObj.textLabel.Text = textData.text
	floatingTextObj.textLabel.TextColor3 = textData.color
	
	if textData.centered then
		floatingTextObj.textLabel.TextXAlignment = Enum.TextXAlignment.Center
	else
		floatingTextObj.textLabel.TextXAlignment = Enum.TextXAlignment.Left
	end

	floatingTextObj.part.Position = textData.worldPos

	floatingTextObj.billboardGui.StudsOffset = Vector3.new(textData.xOffset, 0.07, 0)
	floatingTextObj.billboardGui.AlwaysOnTop = textData.alwaysOnTop

	floatingTextObj.billboardGui.Enabled = true
end

function DebugRenderer.createFloatingTextObject(): FloatingTextObject
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.fromScale(1, 1)
	billboardGui.StudsOffset = Vector3.new(0, 0.07, 0)
	billboardGui.Adornee = nil :: any
	billboardGui.AlwaysOnTop = true
	billboardGui.LightInfluence = 0

	local textLabel = Instance.new("TextLabel")
	textLabel.AutomaticSize = Enum.AutomaticSize.X
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = ""
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.FontFace = Font.fromName("RobotoMono")
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = billboardGui

	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = Vector3.new(0, 0, 0)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.AudioCanCollide = false
	part.Transparency = 1
	part.Parent = workspace
	
	billboardGui.Adornee = part
	billboardGui.Parent = debugRendererScreenGui
	
	local floatingTextObj: FloatingTextObject = {
		part = part,
		textLabel = textLabel,
		billboardGui = billboardGui,
		inUse = false
	}

	return floatingTextObj
end

function DebugRenderer.createScreenGui(): ScreenGui
	local newScreenGui = Instance.new("ScreenGui")
	newScreenGui.Name = "DebugRenderer"
	newScreenGui.IgnoreGuiInset = true
	newScreenGui.ResetOnSpawn = false
	newScreenGui.Parent = localPlayer.PlayerGui

	return newScreenGui
end

return DebugRenderer