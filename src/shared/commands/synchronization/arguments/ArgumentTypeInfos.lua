--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)
local EntityArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.asymptote.EntityArgumentInfo)
local ItemArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.asymptote.ItemArgumentInfo)
local JsonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.asymptote.JsonArgumentInfo)
local Vector3ArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.asymptote.Vector3ArgumentInfo)
local BooleanArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.default.BooleanArgumentInfo)
local IntegerArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.default.IntegerArgumentInfo)
local StringArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.default.StringArgumentInfo)

--[=[
	@class ArgumentTypeInfos

	Maintains all argument types for serialization and deserialization for sending to the network.
]=]
local ArgumentTypeInfos = {}

local registry = {}
local registry_by_class = {}

local function register(registry: { [any]: any }, id: string, info: SingletonArgumentInfo.SingletonArgumentInfo): ()
	registry[id] = info
	registry_by_class[info.type] = info
end

function ArgumentTypeInfos.register(registry: { [any]: any }): ()
	register(registry, "bool", BooleanArgumentInfo :: any)
	register(registry, "str", StringArgumentInfo :: any)
	register(registry, "int", IntegerArgumentInfo :: any)
	register(registry, "vec3", Vector3ArgumentInfo :: any)
	register(registry, "entity", EntityArgumentInfo :: any)
	register(registry, "item", ItemArgumentInfo :: any)
	register(registry, "json", JsonArgumentInfo :: any)
end

function ArgumentTypeInfos.byClass<S>(argument: ArgumentType.ArgumentType<S>): SingletonArgumentInfo.SingletonArgumentInfo
	return registry_by_class[getmetatable(argument) :: any]
end

function ArgumentTypeInfos.bySerializedTable(serialized: { [any]: any }): SingletonArgumentInfo.SingletonArgumentInfo
	return registry[serialized.type]
end

ArgumentTypeInfos.register(registry)

return ArgumentTypeInfos