--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
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
	disguiseClothings: DisguiseClothings
}, PropDisguiseGiver))

export type DisguiseClothings = {
	Shirt: Content,
	Pants: Content
}

function PropDisguiseGiver.new(model: Model, disguiseName: string, disguiseClothings: DisguiseClothings): PropDisguiseGiver
	return setmetatable({
		model = model,
		disguiseName = disguiseName,
		disguiseClothings = disguiseClothings
	}, PropDisguiseGiver)
end

function PropDisguiseGiver.setupProximityPrompt(self: PropDisguiseGiver)
	local primaryPart = self.model.PrimaryPart
	if not primaryPart then return end

	local triggerAttachment = primaryPart:FindFirstChild("Trigger")
	if not (triggerAttachment and triggerAttachment:IsA("Attachment")) then
		return
	end

	local newProxPrompt = Instance.new("ProximityPrompt")
	newProxPrompt.ActionText = "Disguise"
	newProxPrompt.ObjectText = self.disguiseName
	newProxPrompt.ClickablePrompt = true
	newProxPrompt.HoldDuration = 5
	newProxPrompt.KeyboardKeyCode = Enum.KeyCode.E
	newProxPrompt.RequiresLineOfSight = true
	newProxPrompt.Parent = triggerAttachment
	newProxPrompt.Triggered:Connect(function(player)
		self:applyDisguiseToPlayer(player)
	end)
	newProxPrompt.PromptButtonHoldBegan:Connect(function(player)
		local playerStatus = PlayerStatusRegistry.getPlayerStatuses(player)
		playerStatus:addStatus("CRIMINAL_SUSPICIOUS")
	end)
	newProxPrompt.PromptButtonHoldEnded:Connect(function(player)
		local playerStatus = PlayerStatusRegistry.getPlayerStatuses(player)
		playerStatus:removeStatus("CRIMINAL_SUSPICIOUS")
	end)
end

function PropDisguiseGiver.applyDisguiseToPlayer(self: PropDisguiseGiver, player: Player): ()
	local playerStatus = PlayerStatusRegistry.getPlayerStatuses(player)
	if playerStatus:hasStatus("DISGUISED") then
		return
	end

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
	shirtClothing.ShirtTemplate = disguiseShirtContent.Uri
	local pantsClothing = Instance.new("Pants")
	pantsClothing.PantsTemplate = disguisePantsContent.Uri

	shirtClothing.Parent = playerCharacter
	pantsClothing.Parent = playerCharacter

	playerStatus:addStatus("DISGUISED")

	local disguiseOnSound = DISGUISE_ON_SOUND:Clone()
	disguiseOnSound.Parent = playerCharacter.PrimaryPart
	disguiseOnSound.PlayOnRemove = true
	disguiseOnSound:Destroy()
end

return PropDisguiseGiver