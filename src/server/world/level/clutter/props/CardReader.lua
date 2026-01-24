--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStatusTypes = require(ReplicatedStorage.shared.player.PlayerStatusTypes)
local InteractionPromptBuilder = require(ReplicatedStorage.shared.world.interaction.InteractionPromptBuilder)
local PlayerStatusRegistry = require(ServerScriptService.server.player.PlayerStatusRegistry)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

local LIGHT_TRUE = BrickColor.new("Slime green")
local LIGHT_FALSE = BrickColor.new("Crimson")

--[=[
	@class CardReader
]=]
local CardReader = {}
CardReader.__index = CardReader

export type CardReader = typeof(setmetatable({} :: {
	lightLevelParts: { BasePart},
	validCards: { [string]: true },
	triggerVariableName: string,
	acceptSound: Sound
}, CardReader))

function CardReader.new(
	validCards: { [string]: true },
	triggerVariableName: string,
	lightLevelParts: { BasePart},
	acceptSound: Sound
): CardReader
	return setmetatable({
		validCards = validCards,
		triggerVariableName = triggerVariableName,
		lightLevelParts = lightLevelParts,
		acceptSound = acceptSound
	}, CardReader)
end

function CardReader.onPromptTriggered(self: CardReader, player: Player): ()
	if next(self.validCards) == nil then
		return
	end

	for cardName in self.validCards do
		local cardInst = player.Backpack:FindFirstChild(cardName) or (player.Character :: Model):FindFirstChild(cardName)
		if cardInst and cardInst:IsA("Tool") then
			GlobalStatesHolder.setState(self.triggerVariableName, true)
			self.acceptSound:Play()
			break
		end
	end
end

function CardReader.onTriggerVariableChanged(self: CardReader, value: boolean): ()
	if value then
		self:setLightPartColors(LIGHT_TRUE)
	else
		self:setLightPartColors(LIGHT_FALSE)
	end
end

function CardReader.setLightPartColors(self: CardReader, color: BrickColor): ()

	for _, lightPart in self.lightLevelParts do
		lightPart.BrickColor = color
	end
end

function CardReader.createFromModel(placeholder: BasePart, model: Model, serverLevel: ServerLevel.ServerLevel): CardReader
	local base = (model :: any).Base :: BasePart
	local part0 = (model :: any).Part0 :: BasePart

	local triggerVariable = base:GetAttribute("TriggerVariable") :: string

	-- Proximity prompt

	local prompt = InteractionPromptBuilder.new()
		:withPrimaryInteractionKey()
		:withTitleKey("ui.prompt.unlock")
		:withHoldStatus(`1`)
		:withHoldDuration(0.5)
		:withActivationDistance(4)
		:withOmniDir(false)
		:create(part0, serverLevel:getExpressionContext())

	-- Global states
	if not GlobalStatesHolder.hasState(triggerVariable) then
		GlobalStatesHolder.setState(triggerVariable, false)
	end
	local variableState = GlobalStatesHolder.getState(triggerVariable)

	-- Lights

	local START_FROM = 1
	local PREFIX = "Light"

	local lightLevel = (base:GetAttribute("LightLevel") or 1) :: number
	math.clamp(lightLevel, 1, 4)
	local i = START_FROM
	local lightParts: { BasePart } = {}

	--[[
		Light level:

		1:
		Light1: 0
		Light2: 0
		Light3: 0
		Light4: 0

		2:
		Light1: 1
		Light2: 0
		Light3: 0
		Light4: 0

		3:
		Light1: 1
		Light2: 1
		Light3: 0
		Light4: 0

		4:
		Light1: 1
		Light2: 1
		Light3: 1
		Light4: 0
	]]

	while true do
		local lightPart = model:FindFirstChild(PREFIX .. i) :: BasePart?
		if not lightPart then
			break
		end

		table.insert(lightParts, lightPart)
		i += 1
	end

	for index, lightPart in lightParts do
		lightPart.BrickColor = variableState and LIGHT_TRUE or LIGHT_FALSE
		local transparencyValue = 0
		-- If the index is less than the current level (e.g., L1, L2, L3 for Level 4),
		-- the value in the pattern is 1, which corresponds to Transparency = 1 (invisible).
		if index < lightLevel then
			transparencyValue = 1 
		
		-- If the index is equal to the current level (e.g., L4 for Level 4),
		-- the value in the pattern is 0, which corresponds to Transparency = 0 (visible).
		elseif index == lightLevel then
			transparencyValue = 0

		-- If the index is greater than the current level (e.g., only applicable if there were
		-- more than 4 lights), the light should also be invisible/off (Transparency = 1).
		else
			transparencyValue = 1
		end

		lightPart.Transparency = transparencyValue
	end

	-- Card access

	local validCardsAtt = base:GetAttribute("ValidCards") :: string?
	local validCards: { [string]: true } = {}
	if validCardsAtt then
		for cardName in string.gmatch(validCardsAtt, "%S+") do
			validCards[cardName] = true
		end
	end

	-- Sound

	local acceptSound = ReplicatedStorage.shared.assets.sounds.keycard_accept:Clone()
	acceptSound.Parent = part0

	-- Setup

	local newReader = CardReader.new(validCards, triggerVariable, lightParts, acceptSound)

	-- TODO: These may cause a memory leak. Fix this thank you.
	prompt:getTriggeredEvent():Connect(function(player)
		newReader:onPromptTriggered(player)
	end)

	GlobalStatesHolder.getStateChangedConnection(triggerVariable):Connect(function(v)
		if v then
			prompt:disable()
		else
			prompt:enable()
		end
		newReader:onTriggerVariableChanged(v)
	end)

	return newReader
end

return CardReader