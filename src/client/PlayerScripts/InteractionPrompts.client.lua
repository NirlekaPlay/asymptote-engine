--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local Signal = require(ReplicatedStorage.shared.thirdparty.Signal)
local ProximityPrompts = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.interaction.ProximityPrompts)

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local worldInteractionPrompts: { [InteractionPrompt]: true } = {}
local currentPrompt: InteractionPrompt? = nil
local PromptShown = Signal.new() :: Signal.Signal<InteractionPrompt>
local PromptHidden = Signal.new() :: Signal.Signal<InteractionPrompt>

local INF = math.huge

export type InteractionPrompt = {
	configuration: InteractionPromptConfiguration,
	proxPrompt: ProximityPrompt,
	attatchment: Attachment,
	getProximityPrompt: (self: InteractionPrompt) -> ProximityPrompt,
	getAttatchment: (self: InteractionPrompt) -> Attachment,
	--
	WrappedPromptHidden: Signal.Signal<>
}

export type InteractionPromptConfiguration = {
	activationDistance: number
}

--[=[
	This is for registering prompts only, so we do not have to manually traverse
	the entire workspace.
]=]
local function setupInteractionPromptFromProxPrompt(
	proxPrompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType
): ()

	if proxPrompt.Style ~= Enum.ProximityPromptStyle.Custom then
		return
	end

	if not proxPrompt.Parent or not proxPrompt.Parent:IsA("Attachment") then
		warn(`Proximity prompt '{proxPrompt:GetFullName()}' is not parented to an attatchment.`)
		return
	end

	proxPrompt.MaxActivationDistance = 0
	proxPrompt.RequiresLineOfSight = false

	local newInteractionPrompt: InteractionPrompt = {
		configuration = {
			activationDistance = 3
		},
		proxPrompt = proxPrompt,
		attatchment = proxPrompt.Parent,
		getProximityPrompt = function(self: InteractionPrompt): ProximityPrompt
			return proxPrompt
		end,
		getAttatchment = function(self: InteractionPrompt): Attachment
			return proxPrompt.Parent :: Attachment
		end,
		--
		WrappedPromptHidden = Signal.new()
	}

	worldInteractionPrompts[newInteractionPrompt] = true
end

local function update(deltaTime: number): ()
	-- TODO: Handle multiple prompts of different exclusivity types
	if not localPlayer.Character then
		return
	end

	local viewportSize = camera.ViewportSize
	local viewportCenterPos = viewportSize / 2

	local nearestPrompt: InteractionPrompt? = nil
	local nearestDistance = INF

	for interactionPrompt in worldInteractionPrompts do
		if not interactionPrompt:getProximityPrompt().Enabled then
			continue
		end

		local promptAttatchment = interactionPrompt:getAttatchment()
		local promptPos = promptAttatchment.WorldPosition
		local promptParentPart = promptAttatchment.Parent :: BasePart
		local distToLocalPlayerChar = localPlayer:DistanceFromCharacter(promptPos)

		--print("Distance:", distToLocalPlayerChar)
		if distToLocalPlayerChar > interactionPrompt.configuration.activationDistance then
			--print("Not close")
			continue
		end

		local viewport3dPos, onScreen = camera:WorldToViewportPoint(promptPos)

		if not onScreen then
			--print("Not on screen")
			continue
		end

		local obstructingParts = camera:GetPartsObscuringTarget(
			{camera.CFrame.Position, promptPos},{promptParentPart, localPlayer.Character :: Model}
		)

		if next(obstructingParts) ~= nil then
			continue
		end

		local viewport2dPos = Vector2.new(viewport3dPos.X, viewport3dPos.Y)
		local distToScreenCenter = (viewportCenterPos - viewport2dPos).Magnitude

		if distToScreenCenter < nearestDistance then
			nearestDistance = distToScreenCenter
			nearestPrompt = interactionPrompt
		end
	end

	if nearestPrompt and currentPrompt ~= nearestPrompt then
		if currentPrompt then
			currentPrompt:getProximityPrompt().MaxActivationDistance = 0
			currentPrompt.WrappedPromptHidden:Fire()
			PromptHidden:Fire(currentPrompt)
		end
		currentPrompt = nearestPrompt
		-- TODO: Idk if this game will be cross platform,
		-- but make sure to handle the input type correctly.

		-- TODO: Seperate method to handle shown events
		nearestPrompt:getProximityPrompt().MaxActivationDistance = nearestPrompt.configuration.activationDistance
		ProximityPrompts.onPromptShown(nearestPrompt, Enum.ProximityPromptInputType.Keyboard)
		PromptShown:Fire(nearestPrompt)
	elseif nearestPrompt == nil then
		if currentPrompt then
			currentPrompt:getProximityPrompt().MaxActivationDistance = 0
			currentPrompt.WrappedPromptHidden:Fire()
			PromptHidden:Fire(currentPrompt)
		end
		currentPrompt = nil
	end

	ProximityPrompts.update()
end

ProximityPromptService.PromptShown:Connect(setupInteractionPromptFromProxPrompt)

RunService.PreRender:Connect(update)

PromptShown:Connect(function(prompt)
	print("Prompt shown:", prompt)
end)

PromptHidden:Connect(function(prompt)
	print("Prompt hidden:", prompt)
end)
