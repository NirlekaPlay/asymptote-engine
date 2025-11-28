--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)
local BodyColorType = require(ReplicatedStorage.shared.network.types.BodyColorType)

local function applyBodyColors(bodyColorsInst: BodyColors, bodyColors: BodyColorType.BodyColorType): ()
	-- ROBLOX FIX YOUR SHIT
	-- I SWEAR TO GOD THE LIMB COLORS ARE NOT SET
	-- AND YES THE ACTUAL COLOR PROPERTIES OF THE BODY COLORS INSTANCE ARE SET CORRECTLY
	-- BUT NOOOO THE FUCKING LIMB COLORS ARE NOT UPDATED, ONLY IF I FUCKING MANUALLY CHANGE
	-- A COLOR PROPERTY OF THE BODY COLORS INSTANCE FROM THE EDITOR **THEN** THE LIMB COLORS
	-- CHANGES. BUT EVEN WITH THAT BULLSHIT THE HEAD COLOR IS STILL FUCKING GRAY
	-- EVEN THOUGH THE COLOR PROPERTY OF THE HEAD IS SET.
	-- WHAT IN THE RETARDED ASS FUCK IS THIS?!??!?!?!
	bodyColorsInst.HeadColor3 = bodyColors.HeadColor
	bodyColorsInst.LeftArmColor3 = bodyColors.LeftArmColor
	bodyColorsInst.RightArmColor3 = bodyColors.RightArmColor
	bodyColorsInst.LeftLegColor3 = bodyColors.LeftLegColor
	bodyColorsInst.RightLegColor3 = bodyColors.RightLegColor
	bodyColorsInst.TorsoColor3 = bodyColors.TorsoColor
end

TypedRemotes.ClientBoundCharacterAppearances.OnClientEvent:Connect(function(payloads)
	for _, payload in payloads do
		-- TODO: A lil' bit hardcoded
		local bodyColorsInst = payload.character:WaitForChild("Body Colors") :: BodyColors
		applyBodyColors(bodyColorsInst, payload.bodyColors)
	end
end)
