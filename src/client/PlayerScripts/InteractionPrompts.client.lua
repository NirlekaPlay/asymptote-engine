--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local LocalStatesHolder = require(StarterPlayer.StarterPlayerScripts.client.modules.states.LocalStatesHolder)
local ReplicatedGlobalStates = require(StarterPlayer.StarterPlayerScripts.client.modules.states.ReplicatedGlobalStates)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local Signal = require(ReplicatedStorage.shared.thirdparty.Signal)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local worldInteractionPrompts: { [InteractionPrompt]: true } = {}
local registeredProximityPrompts: { [ProximityPrompt]: true } = {}
local currentPrompt: InteractionPrompt? = nil

local DEBUG_PROMPTS = true
local DEBUG_OCCLUSION_RAYS = false
local DEBUG_OCCLUSION_RAYS_LIFETIME = 0.1
local INF = math.huge
local RED = Color3.new(1, 0, 0)
local BLUE = Color3.new(0, 0, 1)
local GREEN = Color3.new(0, 1, 0)

local ATTRIBUTES = {
	PRIMARY_HOLD_CLIENT_CONDITION = "PrimaryHoldClientShowCondition"
}

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

		if DEBUG_OCCLUSION_RAYS then
			local debugRay: BasePart
			if result then
				debugRay = Draw.line(camera.CFrame.Position, result.Position, GREEN)
			else
				debugRay = Draw.raycast(camera.CFrame.Position, direction, RED)
			end

			Debris:AddItem(debugRay, DEBUG_OCCLUSION_RAYS_LIFETIME)
		end
		
		if result and not checkedParts[result.Instance] then
			table.insert(obscuringParts, result.Instance)
			checkedParts[result.Instance] = true
		end
	end
	
	return obscuringParts
end

--[=[
	Returns a new flattened table with values from `t1` and `t2`.
]=]
local function flat(t1: {[any]:any}, t2: {[any]:any}): {[any]:any}
	local newTable: {[any]:any} = {}

	for key, value in pairs(t1) do
		newTable[key] = value
	end

	for key, value in pairs(t2) do
		newTable[key] = value
	end

	return newTable
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
			(self.WrappedPromptHidden :: any):Destroy()
		end,
		--
		WrappedPromptHidden = Signal.new() :: any
	}

	worldInteractionPrompts[newInteractionPrompt] = true
	registeredProximityPrompts[proxPrompt] = true
	
	-- Clean up if the ProximityPrompt is destroyed
	proxPrompt.Destroying:Once(function()
		newInteractionPrompt:destroy()
	end)

	if DEBUG_PROMPTS then
		debugPartsPerPrompt[newInteractionPrompt] = Draw.point(newInteractionPrompt:getAttachment().WorldPosition)
	end
end

--[=[
	Shows and makes the prompt interactible.
]=]
local function showAndEnablePrompt(prompt: InteractionPrompt): ()
	prompt:getProximityPrompt().MaxActivationDistance = prompt.configuration.activationDistance
	if DEBUG_PROMPTS then
		setDebugPointColor(debugPartsPerPrompt[prompt], GREEN)
	end
end

--[=[
	Shows a prompt that can not be interacted, with a text message showing why.
]=]
local function showNonInteractivePrompt(prompt: InteractionPrompt): ()
	prompt:getProximityPrompt().MaxActivationDistance = 0
	if DEBUG_PROMPTS then
		setDebugPointColor(debugPartsPerPrompt[prompt], BLUE)
	end
end

--[=[
	Hides and makes the prompt not interactible.
]=]
local function hideAndDisablePrompt(prompt: InteractionPrompt): ()
	prompt:getProximityPrompt().MaxActivationDistance = 0
	if DEBUG_PROMPTS then
		setDebugPointColor(debugPartsPerPrompt[prompt], RED)
	end
end

--

local function parseCondition(str: string): any
	-- TODO: Idk if parsing and evaluation is expensive, and also I don't seem to be getting
	-- any performance problems on my device, but on low-end devices, this might be a problem.
	-- But oh well, keep moving forward. We're past paralysis by analysis.
	return ExpressionParser.parseAndEvalute(str, ExpressionContext.new(
		flat(
			LocalStatesHolder.getAllStates(),
			ReplicatedGlobalStates.getAllStates()
		)
	))
end

local function evaluatePromptShowCondition(prompt: InteractionPrompt): any
	local conditionAtt = prompt:getAttachment():GetAttribute(ATTRIBUTES.PRIMARY_HOLD_CLIENT_CONDITION) :: string?
	if not conditionAtt or type(conditionAtt) ~= "string" then
		return true -- It doesn't have a condition, so let it show anyway
	end

	return parseCondition(conditionAtt)
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
		--local promptParentPart = promptAttachment.Parent :: BasePart
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

		-- NOTES: Removed the prompt's parent part from the ignore list.
		-- I don't know if this will fuck things up, bho, but I haven't seen any issues so far.
		-- It also fixes the promblem with proximity prompts showing on the other side of the door.
		local obstructingParts = getPartsObscuringTarget(
			camera, {camera.CFrame.Position, promptPos}, {localPlayer.Character :: Model}
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
			end

			currentPrompt = nearestPrompt
			
			local canShow = evaluatePromptShowCondition(nearestPrompt)
			if canShow then
				showAndEnablePrompt(nearestPrompt)
			else
				showNonInteractivePrompt(nearestPrompt)
			end
		else
			if currentPrompt then
				hideAndDisablePrompt(currentPrompt)
				currentPrompt = nil
			end
		end
	end

	if currentPrompt then
		-- TODO: This might get evaluated twice from the previous checks,
		-- may cause performance issues.
		local canShow = evaluatePromptShowCondition(currentPrompt)
		if not canShow then
			showNonInteractivePrompt(currentPrompt)
		end
	end
end

ProximityPromptService.PromptShown:Connect(setupInteractionPromptFromProxPrompt)

RunService.PreRender:Connect(update)