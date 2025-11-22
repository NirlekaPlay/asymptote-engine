--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Signal = require(ReplicatedStorage.shared.thirdparty.Signal)

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local worldInteractionPrompts: { [InteractionPrompt]: true } = {}
local registeredProximityPrompts: { [ProximityPrompt]: true } = {}
local currentPrompt: InteractionPrompt? = nil

local INF = math.huge
local RED = Color3.new(1, 0, 0)
local BLUE = Color3.new(0, 0, 1)
local GREEN = Color3.new(0, 1, 0)

export type InteractionPrompt = {
	configuration: InteractionPromptConfiguration,
	proxPrompt: ProximityPrompt,
	attachment: Attachment,
	getProximityPrompt: (self: InteractionPrompt) -> ProximityPrompt,
	getAttachment: (self: InteractionPrompt) -> Attachment,
	destroy: (self: InteractionPrompt) -> (),
	--
	WrappedPromptHidden: Signal.Signal<>
}

export type InteractionPromptConfiguration = {
	activationDistance: number,
	omniDirectional: boolean
}

--[=[
	Returns BaseParts that are obscuring a target. Unlike `Camera:GetPartsObscuringTarget()`,
	this gives us more control on what part that obscures and what does not.
]=]
local function getPartsObscuringTarget(camera: Camera, castPoints: {Vector3}, ignoreList: {Instance}): {BasePart}
	local obscuringParts: {BasePart} = {}
	local checkedParts: { [BasePart]: boolean } = {}
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = ignoreList or {}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	for _, point in ipairs(castPoints) do
		local direction = (point - camera.CFrame.Position)
		local result = workspace:Raycast(camera.CFrame.Position, direction, raycastParams)
		
		if result and not checkedParts[result.Instance] then
			table.insert(obscuringParts, result.Instance)
			checkedParts[result.Instance] = true
		end
	end
	
	return obscuringParts
end

--

local debugPartsPerPrompt: { [InteractionPrompt]: BasePart } = {}

local function setDebugPointColor(debugPart: BasePart, color: Color3): ()
	local adornment = debugPart:FindFirstChildOfClass("SphereHandleAdornment") :: SphereHandleAdornment
	debugPart.Color = color
	adornment.Color3 = color
end

--[=[
	This is for registering prompts only, so we do not have to manually traverse
	the entire workspace.
]=]
local function setupInteractionPromptFromProxPrompt(
	proxPrompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType
): ()

	if registeredProximityPrompts[proxPrompt] then
		return
	end

	if proxPrompt.Style ~= Enum.ProximityPromptStyle.Custom then
		return
	end

	if not proxPrompt.Parent or not proxPrompt.Parent:IsA("Attachment") then
		warn(`Proximity prompt '{proxPrompt:GetFullName()}' is not parented to an attachment.`)
		return
	end

	local originalMaxActivationDistance = proxPrompt.MaxActivationDistance
	
	proxPrompt.MaxActivationDistance = 0
	proxPrompt.RequiresLineOfSight = false

	local newInteractionPrompt: InteractionPrompt = {
		configuration = {
			activationDistance = originalMaxActivationDistance,
			omniDirectional = (proxPrompt.Parent:GetAttribute("OmniDir") :: boolean?) or true
		},
		proxPrompt = proxPrompt,
		attachment = proxPrompt.Parent,
		getProximityPrompt = function(self: InteractionPrompt): ProximityPrompt
			return proxPrompt
		end,
		getAttachment = function(self: InteractionPrompt): Attachment
			return proxPrompt.Parent :: Attachment
		end,
		destroy = function(self: InteractionPrompt)
			-- Clean up when prompt is destroyed
			worldInteractionPrompts[self] = nil
			registeredProximityPrompts[proxPrompt] = nil
			if currentPrompt == self then
				currentPrompt = nil
			end
			self.WrappedPromptHidden:Destroy()
		end,
		--
		WrappedPromptHidden = Signal.new()
	}

	worldInteractionPrompts[newInteractionPrompt] = true
	registeredProximityPrompts[proxPrompt] = true
	
	-- Clean up if the ProximityPrompt is destroyed
	proxPrompt.Destroying:Once(function()
		newInteractionPrompt:destroy()
	end)

	debugPartsPerPrompt[newInteractionPrompt] = Draw.point(newInteractionPrompt:getAttachment().WorldPosition)
end

--[=[
	Shows and makes the prompt interactible.
]=]
local function showAndEnablePrompt(prompt: InteractionPrompt): ()
	prompt:getProximityPrompt().MaxActivationDistance = prompt.configuration.activationDistance
end

--[=[
	Hides and makes the prompt not interactible.
]=]
local function hideAndDisablePrompt(prompt: InteractionPrompt): ()
	prompt:getProximityPrompt().MaxActivationDistance = 0
end

local function update(deltaTime: number): ()
	-- TODO: Handle multiple prompts of different exclusivity types
	if not localPlayer.Character or not localPlayer.Character.PrimaryPart then
		return
	end

	local viewportSize = camera.ViewportSize
	local viewportCenterPos = viewportSize / 2

	local nearestPrompt: InteractionPrompt? = nil
	local nearestDistance = INF

	for interactionPrompt in worldInteractionPrompts do
		local proxPrompt = interactionPrompt:getProximityPrompt()
		
		if not proxPrompt or not proxPrompt.Parent or not proxPrompt.Enabled then
			continue
		end

		local promptAttachment = interactionPrompt:getAttachment()
		
		if not promptAttachment or not promptAttachment.Parent then
			continue
		end
		
		local promptPos = promptAttachment.WorldPosition
		local promptParentPart = promptAttachment.Parent :: BasePart
		local distToLocalPlayerChar = localPlayer:DistanceFromCharacter(promptPos)

		if distToLocalPlayerChar > interactionPrompt.configuration.activationDistance then
			continue
		end

		if not interactionPrompt.configuration.omniDirectional then
			local characterHead = (localPlayer.Character :: Model).PrimaryPart :: BasePart
			local attachmentCFrame = promptAttachment.WorldCFrame
			local attachmentLookVector = attachmentCFrame.LookVector
			local vectorToPlayer = (characterHead.Position - attachmentCFrame.Position).Unit
			
			local dotProduct = attachmentLookVector:Dot(vectorToPlayer)
			
			if dotProduct < 0 then
				continue
			end
		end

		local viewport3dPos, onScreen = camera:WorldToViewportPoint(promptPos)

		if not onScreen then
			continue
		end

		local obstructingParts = getPartsObscuringTarget(
			camera, {camera.CFrame.Position, promptPos}, {promptParentPart, localPlayer.Character :: Model}
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

	if currentPrompt ~= nearestPrompt then
		if nearestPrompt then
			if currentPrompt then
				hideAndDisablePrompt(currentPrompt)
				setDebugPointColor(debugPartsPerPrompt[currentPrompt], RED)
			end

			currentPrompt = nearestPrompt
			showAndEnablePrompt(nearestPrompt)
			setDebugPointColor(debugPartsPerPrompt[nearestPrompt], GREEN)
		else
			if currentPrompt then
				hideAndDisablePrompt(currentPrompt)
				setDebugPointColor(debugPartsPerPrompt[currentPrompt], RED)
				currentPrompt = nil
			end
		end
	end
end

ProximityPromptService.PromptShown:Connect(setupInteractionPromptFromProxPrompt)

RunService.PreRender:Connect(update)