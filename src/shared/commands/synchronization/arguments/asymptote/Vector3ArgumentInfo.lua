--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vector3ArgumentType = require(ReplicatedStorage.shared.commands.arguments.position.Vector3ArgumentType)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)
local FriendlyByteBuf = require(ReplicatedStorage.shared.network.FriendlyByteBuf)

--[=[
	@class Vector3ArgumentInfo
]=]
local Vector3ArgumentInfo = {}
Vector3ArgumentInfo.type = Vector3ArgumentType

function Vector3ArgumentInfo.serializeToTableFromInstance(argumentType: Vector3ArgumentType.Vector3ArgumentType): any
	return { type = "vec3" }
end

function Vector3ArgumentInfo.deserializeFromTable(serialized: any): SingletonArgumentInfo.Template
	local template: SingletonArgumentInfo.Template = {
		instantiate = function(self)
			return Vector3ArgumentType.vec3()
		end
	}
	return template
end

function Vector3ArgumentInfo.serializeToNetwork(buf: FriendlyByteBuf.FriendlyByteBuf, argumentType: Vector3ArgumentType.Vector3ArgumentType): ()
	return
end

function Vector3ArgumentInfo.deserializeFromNetwork(buf: FriendlyByteBuf.FriendlyByteBuf): SingletonArgumentInfo.Template
	return {
		instantiate = function()
			return Vector3ArgumentType.vec3()
		end
	}
end

return Vector3ArgumentInfo