--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local FriendlyByteBuf = require(ReplicatedStorage.shared.network.FriendlyByteBuf)

--[=[
	@class SingletonArgumentInfo

	An interface that describes a singleton that can be used to serialize, deserialize, and instantiate
	command argument types.
]=]
export type SingletonArgumentInfo = {
	serializeToTableFromInstance: <S>(argumentType: ArgumentType.ArgumentType<S>) -> any,
	deserializeFromTable: (serialized: any) -> Template,
	type: ArgumentType.ArgumentType<any>,
	serializeToNetwork: <S>(buf: FriendlyByteBuf.FriendlyByteBuf, argumentType: ArgumentType.ArgumentType<S>) -> (),
	deserializeFromNetwork: (buf: FriendlyByteBuf.FriendlyByteBuf) -> Template
}

export type Template = {
	instantiate: (self: Template) -> ArgumentType.ArgumentType<any>
}

return nil