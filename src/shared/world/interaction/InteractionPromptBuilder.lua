--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStatus = require(ReplicatedStorage.shared.player.PlayerStatus)
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)
local WorldInteractionPrompt = require(ReplicatedStorage.shared.world.interaction.WorldInteractionPrompt)
local TriggerAttributes = require(ReplicatedStorage.shared.world.interaction.attributes.TriggerAttributes)

local ENUM_HOLD_STATUS = {
	NONE = 0,
	MINOR_SUSPICIOUS = 1,
	CRIMINAL_SUSPICIOUS = 2
}

local ENUM_INTERACTION_KEY = {
	PRIMARY = 0,
	SECONDARY = 1
}

local INTERACTION_KEYS_TO_KEYCODES = {
	[ENUM_INTERACTION_KEY.PRIMARY] = Enum.KeyCode.F,
	[ENUM_INTERACTION_KEY.SECONDARY] = Enum.KeyCode.G
}

local DEFAULT_ACTIVATION_DISTANCE = 5
local DEFAULT_HOLD_DUR = 0.3
local DEFAULT_OMNI_DIR = true
local DEFAULT_TITLE_KEY = "ui.prompt.interact"
local DEFAULT_SUBTITLE_KEY = ""
local DEFAULT_NORMAL_ID = Enum.NormalId.Left
local DEFAULT_HOLD_STATUS_EXPR = `{ENUM_HOLD_STATUS.NONE}`
local DEFAULT_SERVER_VISIBLE_EXPR = `true`
local DEFAULT_SERVER_ENABLED_EXPR = `true`
local DEFAULT_DISABLED_SUBTITLE = "'ui.prompt.cant_interact'"
local DEFAULT_DISABLED_TITLE = ""
local DEFAULT_CLIENT_VISIBLE_EXPR = ""
local DEFAULT_CLIENT_ENABLED_EXPR = ""
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
		normalId: Enum.NormalId,
		interactKey: number,
		--
		disabledTitleKey: string,
		--
		serverVisibleExpr: string,
		serverEnabledExpr: string,
		holdStatusExpr: string,
		disabledSubtitleExpr: string,
		clientVisibleExpr: string,
		clientEnabledExpr: string
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
			holdStatusExpr = DEFAULT_HOLD_STATUS_EXPR,
			interactKey = ENUM_INTERACTION_KEY.PRIMARY,
			tag = nil :: string?,
			--
			serverVisibleExpr = DEFAULT_SERVER_VISIBLE_EXPR,
			serverEnabledExpr = DEFAULT_SERVER_ENABLED_EXPR,
			disabledSubtitleExpr = DEFAULT_DISABLED_SUBTITLE,
			clientVisibleExpr = DEFAULT_CLIENT_VISIBLE_EXPR,
			--
			disabledTitleKey = DEFAULT_DISABLED_TITLE,
			clientEnabledExpr = DEFAULT_CLIENT_ENABLED_EXPR
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
	self.setAttributes.holdStatusExpr = valueExpr
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

--[=[
	Sets the key to interact with this prompt the **Primary Key**.<p>
	Defaults to the **Primary Key**.
]=]
function InteractionPromptBuilder.withPrimaryInteractionKey(self: InteractionPromptBuilder): InteractionPromptBuilder
	self.setAttributes.interactKey = ENUM_INTERACTION_KEY.PRIMARY
	return self
end

--[=[
	Sets the key to interact with this prompt the **Secondary Key**.<p>
	Defaults to the **Primary Key**.
]=]
function InteractionPromptBuilder.withSecondaryInteractionKey(self: InteractionPromptBuilder): InteractionPromptBuilder
	self.setAttributes.interactKey = ENUM_INTERACTION_KEY.SECONDARY
	return self
end

--[=[
	Sets an **expression** that dictates if the prompt should be visible. Evaluated from the server.
]=]
function InteractionPromptBuilder.withServerVisibleExpression(self: InteractionPromptBuilder, serverVisibleExpr: string): InteractionPromptBuilder
	self.setAttributes.serverVisibleExpr = serverVisibleExpr
	return self
end

--[=[
	Sets an **expression** that dictates if the prompt should be enabled. If the prompt is disabled,
	uses the prompt's disabled subtitle to tell the player why it is disabled.
]=]
function InteractionPromptBuilder.withServerEnabledExpression(self: InteractionPromptBuilder, serverEnabledExpr: string): InteractionPromptBuilder
	self.setAttributes.serverEnabledExpr = serverEnabledExpr
	return self
end

--[=[
	Sets an **expression** returning a key to a localized string. If the prompt is disabled, the localized string
	returned by this expression is used to tell the player why it is disabled.
]=]
function InteractionPromptBuilder.withDisabledSubtitleExpr(self: InteractionPromptBuilder, disabledSubtitleExpr: string): InteractionPromptBuilder
	self.setAttributes.disabledSubtitleExpr = disabledSubtitleExpr
	return self
end

--[=[
	Sets an expression that is evaluated on the client and dictates if the prompt should be shown or not.<p>
	Defaults to an empty string.
]=]
function InteractionPromptBuilder.withClientVisibleExpression(self: InteractionPromptBuilder, clientVisibleExpr: string): InteractionPromptBuilder
	self.setAttributes.clientVisibleExpr = clientVisibleExpr
	return self
end

--[=[
	Sets an expression that is evaluated on the client and dictates if the prompt should be interactable.<p>
	Defaults to an empty string.
]=]
function InteractionPromptBuilder.withClientEnabledExpression(self: InteractionPromptBuilder, clientEnabledExpr: string): InteractionPromptBuilder
	self.setAttributes.clientEnabledExpr = clientEnabledExpr
	return self
end

--[=[
	Sets the bigger text that shows when this prompt is disabled. `disabledTitleKey` must be a localised string.<p>
	Defaults to an empty string.
]=]
function InteractionPromptBuilder.withDisabledTitleKey(self: InteractionPromptBuilder, disabledTitleKey: string): InteractionPromptBuilder
	self.setAttributes.disabledTitleKey = disabledTitleKey
	return self
end

--

--[=[
	Builds and creates and returns an instance of `WorldInteractionPrompt`.
]=]
function InteractionPromptBuilder.create(self: InteractionPromptBuilder, parentPart: BasePart, expressionContext: ExpressionContext.ExpressionContext): WorldInteractionPrompt.WorldInteractionPrompt
	local setAttributes = self.setAttributes
	local attachment = InteractionPromptBuilder.createAttachmentAtNormal(parentPart, ATTACHMENT_NAME, setAttributes.normalId)

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.MaxActivationDistance = setAttributes.activationDist
	proximityPrompt.ActionText = setAttributes.titleKey
	proximityPrompt.ObjectText = setAttributes.subtitleKey
	proximityPrompt.ClickablePrompt = true
	proximityPrompt.HoldDuration = setAttributes.holdDur
	proximityPrompt.KeyboardKeyCode = INTERACTION_KEYS_TO_KEYCODES[setAttributes.interactKey]
	proximityPrompt.RequiresLineOfSight = true
	proximityPrompt.Style = Enum.ProximityPromptStyle.Custom

	if setAttributes.tag then
		attachment:AddTag(setAttributes.tag)
	end

	attachment:SetAttribute(TriggerAttributes.OMNIDIRECTIONAL, setAttributes.omniDir)

	--

	local parsedServerVisibleExpr = ExpressionParser.fromString(setAttributes.serverVisibleExpr):parse() :: ExpressionParser.ASTNode
	local serverVisibleExprUsedVars = ExpressionParser.getVariablesSet(parsedServerVisibleExpr)

	local parsedServerEnabledExpr = ExpressionParser.fromString(setAttributes.serverEnabledExpr):parse() :: ExpressionParser.ASTNode
	local serverEnabledExprUsedVars = ExpressionParser.getVariablesSet(parsedServerEnabledExpr)

	local parsedDisabledSubtitleExpr = ExpressionParser.fromString(setAttributes.disabledSubtitleExpr):parse() :: ExpressionParser.ASTNode
	local disabledSubtitleUsedVars = ExpressionParser.getVariablesSet(parsedDisabledSubtitleExpr)

	attachment:SetAttribute(TriggerAttributes.SERVER_VISIBLE, ExpressionParser.evaluate(parsedServerVisibleExpr, expressionContext))
	attachment:SetAttribute(TriggerAttributes.SERVER_ENABLED, ExpressionParser.evaluate(parsedServerEnabledExpr, expressionContext))
	attachment:SetAttribute(TriggerAttributes.DISABLED_SUBTITLE, ExpressionParser.evaluate(parsedDisabledSubtitleExpr, expressionContext))
	attachment:SetAttribute(TriggerAttributes.DISABLED_TITLE, setAttributes.disabledTitleKey)
	attachment:SetAttribute(TriggerAttributes.CLIENT_VISIBLE, setAttributes.clientVisibleExpr)
	attachment:SetAttribute(TriggerAttributes.CLIENT_ENABLED, setAttributes.clientEnabledExpr)

	GlobalStatesHolder.getStatesChangedConnection():Connect(function(variableName, variableValue)
		if serverVisibleExprUsedVars[variableName] then
			attachment:SetAttribute(TriggerAttributes.SERVER_VISIBLE, ExpressionParser.evaluate(parsedServerVisibleExpr, expressionContext))
		end

		if serverEnabledExprUsedVars[variableName] then
			attachment:SetAttribute(TriggerAttributes.SERVER_ENABLED, ExpressionParser.evaluate(parsedServerEnabledExpr, expressionContext))
		end

		if disabledSubtitleUsedVars[variableName] then
			attachment:SetAttribute(TriggerAttributes.DISABLED_SUBTITLE, ExpressionParser.evaluate(parsedDisabledSubtitleExpr, expressionContext))
		end
	end)

	--

	local worldPrompt = WorldInteractionPrompt.new(proximityPrompt)

	-- TODO: This should be handled in the WorldProximityPrompt itself
	-- Considering it needs to evaluate an expression

	local setHoldStatusValue = tonumber(setAttributes.holdStatusExpr) :: number
	if setHoldStatusValue ~= ENUM_HOLD_STATUS.NONE then
		-- NOTES: Maybe clean up connections?
		-- I don't see why though, since most prompts are persistent and won't get destroyed anyway

		local giveStatus: PlayerStatus.PlayerStatus
		if setHoldStatusValue == ENUM_HOLD_STATUS.MINOR_SUSPICIOUS then
			giveStatus = PlayerStatusTypes.MINOR_SUSPICIOUS
		elseif setHoldStatusValue == ENUM_HOLD_STATUS.CRIMINAL_SUSPICIOUS then
			giveStatus = PlayerStatusTypes.CRIMINAL_SUSPICIOUS
		end

		worldPrompt:getHoldBeganEvent():Connect(function(player)
			local playerStatus = PlayerStatusRegistry.getPlayerStatusHolder(player)
			if playerStatus then
				playerStatus:addStatus(giveStatus)
			end
		end)

		worldPrompt:getHoldEndedEvent():Connect(function(player)
			local playerStatus = PlayerStatusRegistry.getPlayerStatusHolder(player)
			if playerStatus then
				playerStatus:removeStatus(giveStatus)
			end
		end)
	end

	proximityPrompt.Parent = attachment

	return worldPrompt
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