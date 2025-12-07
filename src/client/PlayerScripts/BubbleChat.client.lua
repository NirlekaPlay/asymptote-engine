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

local DEFAULT_BUBBLE_CHAT_TTL = 5

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
	
	newFrame.Visible = true
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
		local relPos = camera.CFrame:PointToObjectSpace(worldPos)
		local screenPos, _ = camera:WorldToScreenPoint(worldPos)

		-- Since we set AnchorPoint to 0.5, 0.5, 'pos' refers to the center of the frame.
		local halfWidth = contentSize.X / 2
		local halfHeight = contentSize.Y / 2

		local minX = safeAreaPadding.X + halfWidth
		local maxX = viewportSize.X - safeAreaPadding.X - halfWidth
		local minY = safeAreaPadding.Y + halfHeight
		local maxY = viewportSize.Y - safeAreaPadding.Y - halfHeight

		local targetX, targetY

		if relPos.Z > 0 then
			-- It's behind / off-screen.
			local screenDir = Vector2.new(relPos.X, -relPos.Y).Unit
			if screenDir.X ~= screenDir.X then screenDir = Vector2.new(0, -1) end -- NaN check

			-- Push it way out so math.clamp catches it at the border
			targetX = centerScreen.X + (screenDir.X * 100000)
			targetY = centerScreen.Y + (screenDir.Y * 100000)
		else
			-- The bubble chat is in front.
			targetX = screenPos.X
			targetY = screenPos.Y
		end

		local finalX = math.clamp(targetX, minX, maxX)
		local finalY = math.clamp(targetY, minY, maxY)

		frame.Position = UDim2.fromOffset(finalX, finalY)
		frame.Visible = true
	end
end

TypedBubbleChatRemote.OnClientEvent:Connect(function(part, text)
	newBubbleChat(0, text, part)
end)

RunService.PreRender:Connect(function(deltaTime)
	updateBubbleChats(deltaTime)
end)