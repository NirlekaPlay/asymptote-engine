--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardConstants = require(ReplicatedStorage.shared.gunsys.framework.constants.StandardConstants)

local function tagPart(part: BasePart): ()
	-- Tag all character parts as NON_STATIC, so they can be ignored when casting against static geometry
	part:AddTag(StandardConstants.NON_STATIC_TAG)

	-- Tag parts in accessories and tools with RAY_EXCLUDE_TAG so they can be ignored by raycasts
	local accessory = part:FindFirstAncestorWhichIsA("Accessory")
	local tool = part:FindFirstAncestorWhichIsA("Tool")
	if accessory or tool then
		part:AddTag(StandardConstants.RAY_EXCLUDE_TAG)
	end
end

local AccessoryFiltering = {}

function AccessoryFiltering.proccessCharacter(character: Model): ()
	character.DescendantAdded:Connect(function(instance: Instance)
		if instance:IsA("BasePart") then
			tagPart(instance)
		end
	end)

	for _, instance in character:GetDescendants() do
		if instance:IsA("BasePart") then
			tagPart(instance)
		end
	end
end

return AccessoryFiltering