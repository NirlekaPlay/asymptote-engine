--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TriggerAttributes = require(ReplicatedStorage.shared.world.interaction.attributes.TriggerAttributes)

local DEFAULT_ACTIVATION_DISTANCE = 5
local DEFAULT_HOLD_DUR = 0.3
local DEFAULT_OMNI_DIR = true
local DEFAULT_TITLE_KEY = "ui.prompt.interact"
local DEFAULT_SUBTITLE_KEY = ""
local DEFAULT_NORMAL_ID = Enum.NormalId.Left
local ATTACHMENT_NAME = "Trigger"

--[=[
	@class InteractionPromptBuilder

	Serves as a friendly way to create interaction prompts without directly creating attachments,
	setting attributes, or other manual stuff. As the creation of interaction prompts may change.
]=]
local InteractionPromptBuilder = {}
InteractionPromptBuilder.__index = InteractionPromptBuilder

export type InteractionPromptBuilder = typeof(setmetatable({} :: {
	setAttributes: {
		activationDist: number,
		holdDur: number,
		omniDir: boolean,
		titleKey: string,
		subtitleKey: string,
		tag: string?,
		normalId: Enum.NormalId
	}
}, InteractionPromptBuilder))

function InteractionPromptBuilder.new(): InteractionPromptBuilder
	return setmetatable({
		setAttributes = {
			activationDist = DEFAULT_ACTIVATION_DISTANCE,
			holdDur = DEFAULT_HOLD_DUR,
			omniDir = DEFAULT_OMNI_DIR,
			titleKey = DEFAULT_TITLE_KEY,
			subtitleKey = DEFAULT_SUBTITLE_KEY,
			normalId = DEFAULT_NORMAL_ID,
			tag = nil :: string?
		}
	}, InteractionPromptBuilder)
end

--[=[
	Sets the distance a player needs to be in order for the prompt to show.<p>
	Defaults to `5`.
]=]
function InteractionPromptBuilder.withActivationDistance(self: InteractionPromptBuilder, minDist: number): InteractionPromptBuilder
	self.setAttributes.activationDist = minDist
	return self
end

--[=[
	Sets which face of the prompt's parent part will be put on.
	Defaults to `Enum.Normalid.Left`.
]=]
function InteractionPromptBuilder.withAttachmentFacing(self: InteractionPromptBuilder, normal: Enum.NormalId): InteractionPromptBuilder
	self.setAttributes.normalId = normal
	return self
end

--[=[
	Sets the amount of time in seconds needed to complete the interaction.<p>
	Defaults to `0.3`.
]=]
function InteractionPromptBuilder.withHoldDuration(self: InteractionPromptBuilder, holdDur: number): InteractionPromptBuilder
	self.setAttributes.holdDur = holdDur
	return self
end

--[=[
	Sets the status to give to the player when they are holding this prompt.
	Possible numbers for `value`:

	 * `0` No status is given.
	 * `1` Gives the **Minor Suspicious** status.
	 * `2` Gives the **Criminal Suspicious** status.

	Defaults to `0`.

	`valueExpr` must be an **Expression** returning one of these numbers.
]=]
function InteractionPromptBuilder.withHoldStatus(self: InteractionPromptBuilder, valueExpr: string): InteractionPromptBuilder
	return self
end

--[=[
	Sets if the prompt is omni directional or not. Which can be viewed from all angles.
	If `false`, the prompt will face its attachment's positive Z axis.<p>
	Defaults to `true`.
]=]
function InteractionPromptBuilder.withOmniDir(self: InteractionPromptBuilder, omniDir: boolean): InteractionPromptBuilder
	self.setAttributes.omniDir = omniDir
	return self
end

--[=[
	Sets the tag to this prompt that can be used for objectives.
	Defaults to none.
]=]
function InteractionPromptBuilder.withTag(self: InteractionPromptBuilder, tagName: string): InteractionPromptBuilder
	self.setAttributes.tag = tagName
	return self
end

--[=[
	Sets the prompt's bigger text to state its action. Must be a key to a localized string.<p>
	Defaults to `ui.prompt.interact`.
]=]
function InteractionPromptBuilder.withTitleKey(self: InteractionPromptBuilder, titleKey: string): InteractionPromptBuilder
	self.setAttributes.titleKey = titleKey
	return self
end

--[=[
	Sets the prompt's smaller text to state the object its acting on. Must be a key to a localized string.<p>
	Defaults to an empty string.
]=]
function InteractionPromptBuilder.withSubtitleKey(self: InteractionPromptBuilder, subtitleKey: string): InteractionPromptBuilder
	self.setAttributes.subtitleKey = subtitleKey
	return self
end

--

--[=[
	Builds and creates and returns an instance of `WorldInteractionPrompt`.
]=]
function InteractionPromptBuilder.create(self: InteractionPromptBuilder, parentPart: BasePart): ()
	local setAttributes = self.setAttributes
	local attachment = InteractionPromptBuilder.createAttachmentAtNormal(parentPart, ATTACHMENT_NAME, setAttributes.normalId)

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.MaxActivationDistance = setAttributes.activationDist
	proximityPrompt.ActionText = setAttributes.titleKey
	proximityPrompt.ObjectText = setAttributes.subtitleKey
	proximityPrompt.ClickablePrompt = true
	proximityPrompt.HoldDuration = setAttributes.holdDur
	proximityPrompt.KeyboardKeyCode = Enum.KeyCode.F -- TODO: Too based on Primary interaction
	proximityPrompt.RequiresLineOfSight = true
	proximityPrompt.Style = Enum.ProximityPromptStyle.Custom

	if setAttributes.tag then
		attachment:AddTag(setAttributes.tag)
	end

	attachment:SetAttribute(TriggerAttributes.OMNIDIRECTIONAL, setAttributes.omniDir)

	proximityPrompt.Parent = attachment

	return
end

--

function InteractionPromptBuilder.createAttachmentAtNormal(inst: BasePart, name: string, normalId: Enum.NormalId): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Parent = inst

	local normalVector = Vector3.FromNormalId(normalId)
	local offset = (inst.Size * normalVector) / 2

	attachment.CFrame = CFrame.lookAt(offset, offset + normalVector)
	
	return attachment
end

return InteractionPromptBuilder