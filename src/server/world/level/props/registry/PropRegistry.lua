--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local PropDisguiseGiver = require(ServerScriptService.server.disguise.PropDisguiseGiver)
local PropHandler = require(ServerScriptService.server.world.level.props.registry.PropHandler)
local PropHandlerBuilder = require(ServerScriptService.server.world.level.props.registry.PropHandlerBuilder)
local DisguisePropsHandler = require(ServerScriptService.server.world.level.props.registry.handlers.DisguisePropsHandler)

--[=[
	@class PropRegistry
]=]
local PropRegistry = {}

local registry: { [string]: PropHandler.PropHandler } = {}

local function register(name: string, handler: PropHandler.PropHandler): ()
	registry[name] = handler
end

function PropRegistry.getHandler(propName: string): PropHandler.PropHandler?
	return registry[propName]
end

function PropRegistry.register(): ()
	register("SpawnLocation", PropHandlerBuilder.new()
		:onProccess(function(placeholder, prop, scene)
			local newSpawnLocation = Instance.new("SpawnLocation")
			local decal = newSpawnLocation:FindFirstChildOfClass("Decal")
			if decal then
				decal:Destroy()
			end
			newSpawnLocation.Anchored = true
			newSpawnLocation.CFrame = placeholder.CFrame
			newSpawnLocation.Size = placeholder.Size
			newSpawnLocation.Transparency = 1
			newSpawnLocation.CanCollide = false
			newSpawnLocation.CanQuery = false
			newSpawnLocation.CanTouch = false
			newSpawnLocation.AudioCanCollide = false
			newSpawnLocation.Duration = 0
			newSpawnLocation.Parent = placeholder.Parent
			placeholder:Destroy()
			return true, nil
		end)
		:build()
	)

	register("DisguiseTrigger", PropHandlerBuilder.new()
		:onProccess(function(placeholder: BasePart, prop: Model?, scene)
			local disguiseName = placeholder:GetAttribute("Disguise") :: any
			if not disguiseName then
				error(`Failed to create disguise giver: On {placeholder:GetFullName()} placeholder does not have 'Disguise' attribute.`)
			end
			if type(disguiseName) ~= "string" then
				error(`Failed to create disguise giver: On {placeholder:GetFullName()} 'Disguise' attribute must be a string.`)
			end
			if disguiseName == "" then
				error(`Failed to create disguise giver: On {placeholder:GetFullName()} 'Disguise' is an empty string.`)
			end

			-- im too lazy to add further checks.

			-- backwards compatibility with InfiltrationEngine:

			-- i think this should be on the client side but idfk.
			local disguiseProfile = scene:getSceneConfig():getDisguiseConfig(disguiseName)
			local localizedDisguiseName = disguiseProfile.nameLocalizedKey
			local shirtId = disguiseProfile.outfitIds[1][1]
			local pantsId = disguiseProfile.outfitIds[1][2]

			-- For some reason, in InfiltrationEngine, the axis to make the
			-- prompt forward face is the positive X axis instead of the typical
			-- positive Z axis like LookVectors.

			local triggerAttachment = Instance.new("Attachment")
			triggerAttachment.Name = "Trigger"
			triggerAttachment.Parent = placeholder

			-- Position it half a unit along the placeholder's X axis
			local halfSize = placeholder.Size.X / 2

			-- Create a CFrame that positions AND orients the attachment
			-- Position: halfSize units along X axis (in object space)
			-- Orientation: Z axis faces along the placeholder's X axis (so -X direction in object space)
			triggerAttachment.CFrame = CFrame.new(-halfSize, 0, 0) * CFrame.lookAt(Vector3.zero, -Vector3.new(1, 0, 0))

			-- what the shit.
			local model = Instance.new("Model")
			model.Name = placeholder.Name
			model.PrimaryPart = placeholder
			model.Parent = placeholder.Parent

			local newDisguiser = PropDisguiseGiver.new(model, disguiseName, localizedDisguiseName, {
				Shirt = Content.fromAssetId(shirtId),
				Pants = Content.fromAssetId(pantsId)
			}, nil, disguiseProfile.disguiseClass)

			newDisguiser:setupProximityPrompt(scene:getExpressionContext())

			placeholder.Transparency = 1
			placeholder.CanCollide = false
			placeholder.CanQuery = false
			placeholder.CanTouch = false
			placeholder.AudioCanCollide = false

			return true, nil
		end)
		:build()
	)

	register("ClothingRack", DisguisePropsHandler)

	register("LaundryBasket", DisguisePropsHandler)

	register("FloatingFlatText", PropHandlerBuilder.new():onProccess(function(placeholder: BasePart, prop: Model?, scene)
		placeholder:AddTag("Clutter")
		placeholder:SetAttribute("ClutterPropName", "FloatingFlatText")
		placeholder.Transparency = 1
		placeholder.CanCollide = false
		placeholder.CanQuery = false
		placeholder.CanTouch = false
		placeholder.AudioCanCollide = false
		return true, nil
	end):build())

	
end

PropRegistry.register()

return PropRegistry