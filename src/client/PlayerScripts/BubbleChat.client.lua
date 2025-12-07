--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local ClientLanguage = require(StarterPlayer.StarterPlayerScripts.client.modules.language.ClientLanguage)
local UITextShadow = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.UITextShadow)
local TypedBubbleChatRemote = require(ReplicatedStorage.shared.network.remotes.TypedRemotes).BubbleChat

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
local bubbleChatUi = playerGui:WaitForChild("BubbleChat")

local VERTICAL_OFFSET_PIXELS = 55
local DEFAULT_BUBBLE_CHAT_TTL = 5
local EPSILON = 1e-5

type BubbleChat = {
	parentedTo: BasePart,
	directedTo: number,
	message: string,
	ttl: number,
	uiInstances: {
		frame: Frame,
		msgTextLabel: TextLabel,
		msgTextLabelShadow: TextLabel
	}
}

local bubbleChatsSet: { [BasePart]: BubbleChat } = {}

local function deleteBubbleChat(bubbleChat: BubbleChat): ()
	if bubbleChat.uiInstances.frame then
		bubbleChat.uiInstances.frame:Destroy()
	end
	bubbleChatsSet[bubbleChat.parentedTo] = nil
end

local function newBubbleChat(directedTo: number, message: string, parent: BasePart): ()
	local existing = bubbleChatsSet[parent]
	local msg = ClientLanguage.getOrDefault(message, message)

	if existing then
		existing.message = msg
		existing.ttl = DEFAULT_BUBBLE_CHAT_TTL
		existing.uiInstances.msgTextLabel.Text = msg
		existing.uiInstances.msgTextLabelShadow.Text = msg
		return
	end

	local frameToClone = bubbleChatUi.Root.SafeArea.REF
	local newFrame = frameToClone:Clone()
	local msgTextLabel = newFrame.Message
	local msgTextLabel_shadow = UITextShadow.createTextShadow(msgTextLabel, nil, 3)
	
	msgTextLabel_shadow.BackgroundTransparency = 1
	msgTextLabel.Text = msg
	msgTextLabel_shadow.Text = msg
	
	-- Ensure the Frame is center-anchored for easier clamping logic
	newFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	-- Disable AutomaticSize on the frame so we can control it manually
	newFrame.AutomaticSize = Enum.AutomaticSize.None 
	
	--newFrame.Visible = true
	newFrame.Parent = frameToClone.Parent

	local newBubbleChatData = {
		parentedTo = parent,
		directedTo = directedTo,
		message = message,
		ttl = DEFAULT_BUBBLE_CHAT_TTL,
		uiInstances = {
			frame = newFrame,
			msgTextLabel = msgTextLabel,
			msgTextLabelShadow = msgTextLabel_shadow
		}
	}

	bubbleChatsSet[parent] = newBubbleChatData :: BubbleChat -- shut up.
end

local function updateBubbleChats(deltaTime: number): ()
	local camera = workspace.CurrentCamera
	if not camera then return end

	local viewportSize = camera.ViewportSize
	local centerScreen = viewportSize / 2
	local safeAreaPadding = Vector2.new(10, 10)

	for part, bubbleChat in bubbleChatsSet do
		bubbleChat.ttl -= deltaTime
		
		local shouldRemove = false
		if bubbleChat.ttl <= 0 then
			shouldRemove = true
		elseif not part or not part:IsDescendantOf(workspace) then
			shouldRemove = true
		end

		if shouldRemove then
			deleteBubbleChat(bubbleChat)
			continue
		end

		local frame = bubbleChat.uiInstances.frame
		local textLabel = bubbleChat.uiInstances.msgTextLabel
		
		local contentSize = textLabel.AbsoluteSize
		frame.Size = UDim2.fromOffset(contentSize.X, contentSize.Y)

		local worldPos = part.Position
		
		local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)

		local adjustedScreenY = screenPos.Y - VERTICAL_OFFSET_PIXELS

		local halfWidth = contentSize.X / 2
		local halfHeight = contentSize.Y / 2

		local maxBoundsX = (viewportSize.X / 2) - safeAreaPadding.X - halfWidth
		local maxBoundsY = (viewportSize.Y / 2) - safeAreaPadding.Y - halfHeight

		local rX = screenPos.X - centerScreen.X
		local rY = adjustedScreenY - centerScreen.Y
		
		if screenPos.Z < 0 then
			rX = -rX
			rY = -rY
		end

		local absX = math.abs(rX)
		local absY = math.abs(rY)
		
		local scaleX = maxBoundsX / math.max(absX, EPSILON) -- Use epsilon to avoid division by zero
		local scaleY = maxBoundsY / math.max(absY, EPSILON)
		
		local scale = math.min(scaleX, scaleY)
		
		local finalX, finalY

		if onScreen and scale >= 1 then
			finalX = screenPos.X
			finalY = adjustedScreenY
		else
			finalX = centerScreen.X + (rX * scale)
			finalY = centerScreen.Y + (rY * scale)
		end

		frame.Position = UDim2.fromOffset(finalX, finalY)
		
		if not frame.Visible then
			task.wait() -- Fix a thing where the frame lags behind before being properly positioned.
			frame.Visible = true
		end
	end
end

TypedBubbleChatRemote.OnClientEvent:Connect(function(part, text)
	newBubbleChat(0, text, part)
end)

RunService.PreRender:Connect(function(deltaTime)
	updateBubbleChats(deltaTime)
end)