--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StateComponent = require(ServerScriptService.server.world.level.components.registry.StateComponent)
local StateComponentRegistry = require(ServerScriptService.server.world.level.components.registry.StateComponentRegistry)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local UString = require(ReplicatedStorage.shared.util.string.UString)

local COMPONENT_TYPE_ATTRIBUTE_NAME = "Type"

--[=[
	@class StateComponentFactory
]=]
local StateComponentFactory = {}

function StateComponentFactory.create(instance: Instance, context: ExpressionContext.ExpressionContext): StateComponent.StateComponent?
	local typeName = StateComponentFactory.getComponentType(instance) or instance.Name
	local creator = StateComponentRegistry[typeName]
	
	if creator then
		return creator(instance, context)
	end

	return nil
end

function StateComponentFactory.getComponentType(instance: Instance): string?
	local specifiedType = instance:GetAttribute(COMPONENT_TYPE_ATTRIBUTE_NAME)
	if type(specifiedType) ~= "string" then
		return nil
	end

	if UString.isBlank(specifiedType) then
		return nil
	end

	return specifiedType
end

return StateComponentFactory