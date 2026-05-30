--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local PropDisguiseGiver = require(ServerScriptService.server.disguise.PropDisguiseGiver)

local DisguisePropsHandler = {}

function DisguisePropsHandler.proccess(_, placeholder, prop, scene): (boolean, any)
	local disguiseName = placeholder:GetAttribute("Disguise") :: string
	if disguiseName == "" then
		warn(`The Disguise attribute of {placeholder:GetFullName()} is an empty string.`)
		return false
	end

	if not prop then
		return false, nil
	end

	local disguiseProfile = scene:getSceneConfig():getDisguiseConfig(disguiseName)
	local localizedDisguiseName = disguiseProfile.nameLocalizedKey
	local shirtId = disguiseProfile.outfitIds[1][1]
	local pantsId = disguiseProfile.outfitIds[1][2]

	local newDisguiser = PropDisguiseGiver.new(prop, disguiseName, localizedDisguiseName, {
		Shirt = Content.fromAssetId(shirtId),
		Pants = Content.fromAssetId(pantsId)
	}, nil, disguiseProfile.disguiseClass)

	newDisguiser:setupProximityPrompt(scene:getExpressionContext())

	return true, nil
end

return DisguisePropsHandler