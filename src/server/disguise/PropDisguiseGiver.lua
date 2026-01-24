--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local InteractionPromptBuilder = require(ReplicatedStorage.shared.world.interaction.InteractionPromptBuilder)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)

local DISGUISE_ON_SOUND = ReplicatedStorage.shared.assets.sounds.disguise_equip

--[=[
	@class PropDisguiseGiver

	Gives a Player a disguise.
]=]
local PropDisguiseGiver = {}
PropDisguiseGiver.__index = PropDisguiseGiver

export type PropDisguiseGiver = typeof(setmetatable({} :: {
	model: Model,
	disguiseName: string,
	disguiseId: string,
	disguiseClothings: DisguiseClothings,
	disguiseUpperColor: BrickColor?,
	disguiseClass: number
}, PropDisguiseGiver))

export type DisguiseClothings = {
	Shirt: Content,
	Pants: Content
}

function PropDisguiseGiver.new(model: Model, disguiseId: string, disguiseName: string, disguiseClothings: DisguiseClothings, disguiseUpperColor: BrickColor?, disguiseClass: number?): PropDisguiseGiver
	return setmetatable({
		model = model,
		disguiseName = disguiseName,
		disguiseId = disguiseId,
		disguiseClothings = disguiseClothings,
		disguiseUpperColor = disguiseUpperColor,
		disguiseClass = disguiseClass or 0
	}, PropDisguiseGiver)
end

function PropDisguiseGiver.setupProximityPrompt(self: PropDisguiseGiver, expressionContext: ExpressionContext.ExpressionContext)
	local primaryPart = (self.model:FindFirstChild("Base") or self.model.PrimaryPart) :: BasePart
	if not primaryPart then
		warn(`Failed to set disguise trigger: `, self.model, ` does not have a 'Base' or Primary part.`)
		return
	end

	local prompt = InteractionPromptBuilder.new()
		:withPrimaryInteractionKey()
		:withTitleKey("ui.prompt.disguise")
		:withSubtitleKey(self.disguiseName)
		:withHoldDuration(5)
		:withActivationDistance(5)
		:withOmniDir(false)
		:withHoldStatus("2") 
		:withClientEnabledExpression(`!(CurrentPlayerDisguise == '{self.disguiseId}')`)
		:withDisabledSubtitleExpr("'ui.prompt.already_disguised'")
		:withPrimaryInteractionKey()

	local triggerAttachment = primaryPart:FindFirstChild("Trigger") :: Attachment?
	local worldPrompt = prompt:create(primaryPart, expressionContext, triggerAttachment)

	worldPrompt:getTriggeredEvent():Connect(function(player)
		self:applyDisguiseToPlayer(player)
	end)
end

function PropDisguiseGiver.applyDisguiseToPlayer(self: PropDisguiseGiver, player: Player): ()
	local curDisAtt = (player.Character :: Model):GetAttribute("CurrentPlayerDisguise")
	if curDisAtt and curDisAtt == self.disguiseId then
		return
	end

	(player.Character :: Model):SetAttribute("CurrentDisguiseClass", self.disguiseClass);
	(player.Character :: Model):SetAttribute("CurrentPlayerDisguise", self.disguiseId)

	local playerStatus = PlayerStatusRegistry.getPlayerStatusHolder(player)

	playerStatus:setDisguise(self.disguiseId)

	local playerCharacter = player.Character
	if not playerCharacter then return end

	for _, clothing in ipairs(playerCharacter:GetChildren()) do
		if not clothing:IsA("Clothing") then
			continue
		end
		-- TODO: add check to see if the player's clothes already has the required disguise clothes.
		clothing:Destroy()
	end

	local disguiseShirtContent = self.disguiseClothings.Shirt
	local disguisePantsContent = self.disguiseClothings.Pants
	local shirtClothing = Instance.new("Shirt")
	shirtClothing.ShirtTemplate = disguiseShirtContent.Uri :: string
	local pantsClothing = Instance.new("Pants")
	pantsClothing.PantsTemplate = disguisePantsContent.Uri :: string

	shirtClothing.Parent = playerCharacter
	pantsClothing.Parent = playerCharacter

	if self.disguiseUpperColor then
		local humanoidBodyColors = playerCharacter:FindFirstChildOfClass("BodyColors")
		if humanoidBodyColors then
			humanoidBodyColors.TorsoColor = self.disguiseUpperColor
			humanoidBodyColors.LeftArmColor = self.disguiseUpperColor
			humanoidBodyColors.RightArmColor = self.disguiseUpperColor
		end
	end

	playerStatus:addStatus(PlayerStatusTypes.DISGUISED)

	local disguiseOnSound = DISGUISE_ON_SOUND:Clone()
	disguiseOnSound.Parent = playerCharacter:FindFirstChild("HumanoidRootPart") or playerCharacter
	disguiseOnSound.PlayOnRemove = true
	disguiseOnSound:Destroy()
end

return PropDisguiseGiver