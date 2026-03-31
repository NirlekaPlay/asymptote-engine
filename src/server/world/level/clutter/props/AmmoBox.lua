--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Maid = require(ReplicatedStorage.shared.util.misc.Maid)
local InteractionPromptBuilder = require(ReplicatedStorage.shared.world.interaction.InteractionPromptBuilder)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)

local COMPATIBLE_GUNS = {"FBBeryl", "SuppressedFBBeryl"}

local PROMPT_TEMPLATE = InteractionPromptBuilder.new()
	:withOmniDir(true)
	:withSecondaryInteractionKey()
	:withTitleKey("ui.prompt.replenish")
	:withSubtitleKey("ui.prompt.ammunition")
	:withHoldDuration(3)
	:withHoldStatus("2")
	:withRequiredTools(table.concat(COMPATIBLE_GUNS, " "))
	:withDisabledTitleKey("ui.prompt.replenish")
	:withDisabledSubtitleExpr("'ui.prompt.dont_have_gun'")

--[=[
	@class AmmoBox
]=]
local AmmoBox = {}
AmmoBox.__index = AmmoBox

export type AmmoBox = typeof(setmetatable({} :: {
	sound: Sound,
	maid: Maid.Maid
}, AmmoBox))

function AmmoBox.new(
	sound: Sound,
	maid: Maid.Maid
): AmmoBox
	return setmetatable({
		maid = maid,
		sound = sound
	}, AmmoBox)
end

function AmmoBox.onPromptTriggered(self: AmmoBox, player: Player): ()
	local fbb = nil

	for _, name in COMPATIBLE_GUNS do
		fbb = player.Backpack:FindFirstChild(name) or (player.Character and player.Character:FindFirstChild(name))
		if fbb then
			break
		end
	end

	if fbb then
		self.sound:Play()
		local magsLeft = fbb:GetAttribute("MagsLeft") :: number
		if type(magsLeft) ~= "number" then
			magsLeft = 0
		end
		fbb:SetAttribute("MagsLeft", magsLeft + 4)
	end
end

function AmmoBox.createFromModel(placeholder: BasePart, model: Model, serverLevel: ServerLevel.ServerLevel): AmmoBox
	local sound = model.Box.Ammo :: Sound
	local triggerAtt = model.Box.Trigger :: Attachment
	local maid = Maid.new()

	local prompt = maid:giveTask(PROMPT_TEMPLATE:create(model.Box, serverLevel:getExpressionContext(), triggerAtt))

	local ammoBox = AmmoBox.new(sound, maid)

	maid:giveTask(prompt:getTriggeredEvent():Connect(function(player)
		ammoBox:onPromptTriggered(player)
	end))

	return ammoBox
end

--

function AmmoBox.destroy(self: AmmoBox): ()
	self.maid:doCleaning()
	setmetatable(self, nil)
end

return AmmoBox