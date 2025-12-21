--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
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
	disguiseUpperColor: BrickColor?
}, PropDisguiseGiver))

export type DisguiseClothings = {
	Shirt: Content,
	Pants: Content
}

function PropDisguiseGiver.new(model: Model, disguiseId: string, disguiseName: string, disguiseClothings: DisguiseClothings, disguiseUpperColor: BrickColor?): PropDisguiseGiver
	return setmetatable({
		model = model,
		disguiseName = disguiseName,
		disguiseId = disguiseId,
		disguiseClothings = disguiseClothings,
		disguiseUpperColor = disguiseUpperColor
	}, PropDisguiseGiver)
end

function PropDisguiseGiver.setupProximityPrompt(self: PropDisguiseGiver)
	local primaryPart = self.model:FindFirstChild("Base") or self.model.PrimaryPart
	if not primaryPart then
		warn(`Failed to set disguise trigger: `, self.model, ` does not have a 'Base' or Primary part.`)
		return
	end

	local triggerAttachment = primaryPart:FindFirstChild("Trigger")
	if not (triggerAttachment and triggerAttachment:IsA("Attachment")) then
		warn(`Failed to set disguise trigger: `, self.model, ` does not have a 'Trigger' attatchment.'`)
		return
	end

	-- TODO: Make a Proximity Prompt builder or some shit.
	triggerAttachment:SetAttribute("OmniDir", false)
	triggerAttachment:SetAttribute("PrimaryHoldClientShowCondition", "!HasDisguise")
	triggerAttachment:SetAttribute("PrimaryHoldConditionFailTitle", "ui.prompt.already_disguised")

	local proximityPrompt = triggerAttachment:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
	if not proximityPrompt then
		proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.MaxActivationDistance = 5
		proximityPrompt.ActionText = "Disguise"
		proximityPrompt.ObjectText = self.disguiseName
		proximityPrompt.ClickablePrompt = true
		proximityPrompt.HoldDuration = 5
		proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
		proximityPrompt.RequiresLineOfSight = true
		proximityPrompt.Style = Enum.ProximityPromptStyle.Custom
		proximityPrompt.Parent = triggerAttachment
	end
	-- TODO: Clean up connections.
	-- I dont know why cuz these props are always active in the map but eh
	-- "just in case"
	proximityPrompt.Triggered:Connect(function(player)
		self:applyDisguiseToPlayer(player)
	end)
	proximityPrompt.PromptButtonHoldBegan:Connect(function(player)
		local playerStatus = PlayerStatusRegistry.getPlayerStatusHolder(player)
		playerStatus:addStatus(PlayerStatusTypes.CRIMINAL_SUSPICIOUS)
	end)
	proximityPrompt.PromptButtonHoldEnded:Connect(function(player)
		local playerStatus = PlayerStatusRegistry.getPlayerStatusHolder(player)
		playerStatus:removeStatus(PlayerStatusTypes.CRIMINAL_SUSPICIOUS)
	end)
end

function PropDisguiseGiver.applyDisguiseToPlayer(self: PropDisguiseGiver, player: Player): ()
	local playerStatus = PlayerStatusRegistry.getPlayerStatusHolder(player)
	local isDisguised = playerStatus:hasStatus(PlayerStatusTypes.DISGUISED) -- for some fucking reason, placing it directly to an if statement makes a "unknown" type error bullshit
	if isDisguised then
		return
	end

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