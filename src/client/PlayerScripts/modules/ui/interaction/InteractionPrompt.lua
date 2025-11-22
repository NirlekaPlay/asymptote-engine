--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local InteractionPromptConfiguration = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.interaction.InteractionPromptConfiguration)
local InteractionPromptRenderer = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.interaction.InteractionPromptRenderer)

--[=[
	@class InteractionPrompt
]=]
local InteractionPrompt = {
	RenderStates = {
		INTERACTABLE = 0,
		NON_INTERACTABLE = 1,
		HIDDEN = 3
	}
}
InteractionPrompt.__index = InteractionPrompt

export type InteractionPrompt = typeof(setmetatable({} :: {
	configuration: InteractionPromptConfiguration,
	proxPrompt: ProximityPrompt,
	attachment: Attachment,
	currentRenderState: RenderState,
	activeCleanUpFunc: RenderedPromptCleanUpFunc?
}, InteractionPrompt))

export type RenderState = number
export type RenderedPromptCleanUpFunc = () -> ()

type InteractionPromptConfiguration = InteractionPromptConfiguration.InteractionPromptConfiguration

function InteractionPrompt.new(
	prompt: ProximityPrompt,
	configuration: InteractionPromptConfiguration,
	attachment: Attachment
): InteractionPrompt
	return setmetatable({
		proxPrompt = prompt,
		configuration = configuration,
		attachment = attachment,
		currentRenderState = InteractionPrompt.RenderStates.HIDDEN,
		activeCleanUpFunc = nil :: RenderedPromptCleanUpFunc?
	}, InteractionPrompt)
end

function InteractionPrompt.getAttachment(self: InteractionPrompt): Attachment
	return self.attachment
end

function InteractionPrompt.getProximityPrompt(self: InteractionPrompt): ProximityPrompt
	return self.proxPrompt
end

function InteractionPrompt.getConfiguration(self: InteractionPrompt): InteractionPromptConfiguration
	return self.configuration
end

--

function InteractionPrompt.setActivationDistanceToOriginal(self: InteractionPrompt): ()
	self.proxPrompt.MaxActivationDistance = self.configuration.activationDistance
end

function InteractionPrompt.disableInteraction(self: InteractionPrompt): ()
	self.proxPrompt.MaxActivationDistance = 0
end

--

function InteractionPrompt.showInteractable(self: InteractionPrompt, inputType: Enum.ProximityPromptInputType): ()
	if self.currentRenderState == InteractionPrompt.RenderStates.INTERACTABLE then
		return
	end

	self.currentRenderState = InteractionPrompt.RenderStates.INTERACTABLE

	if self.activeCleanUpFunc then
		task.spawn(function()
			self.activeCleanUpFunc()
		end)
	end

	self:setActivationDistanceToOriginal()

	self.activeCleanUpFunc = InteractionPromptRenderer.createPrompt(
		self:getProximityPrompt(), inputType, InteractionPromptRenderer.getScreenGui()
	)
end

function InteractionPrompt.showNonInteractable(self: InteractionPrompt, failMsg: string): ()
	if self.currentRenderState == InteractionPrompt.RenderStates.NON_INTERACTABLE then
		return
	end

	self.currentRenderState = InteractionPrompt.RenderStates.NON_INTERACTABLE

	if self.activeCleanUpFunc then
		task.spawn(function()
			self.activeCleanUpFunc()
		end)
	end

	self.activeCleanUpFunc = InteractionPromptRenderer.createNonInteractivePrompt(
		self:getProximityPrompt(), failMsg, InteractionPromptRenderer.getScreenGui()
	)

	self:disableInteraction()
end

function InteractionPrompt.hide(self: InteractionPrompt): ()
	if self.currentRenderState == InteractionPrompt.RenderStates.HIDDEN then
		return
	end

	self.currentRenderState = InteractionPrompt.RenderStates.HIDDEN

	if self.activeCleanUpFunc then
		task.spawn(function()
			self.activeCleanUpFunc()
		end)
	end

	self:disableInteraction()
end

return InteractionPrompt