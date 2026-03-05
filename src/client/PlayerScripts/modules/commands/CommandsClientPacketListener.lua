--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local FriendlyByteBuf = require(ReplicatedStorage.shared.network.FriendlyByteBuf)
local ClientboundCommandsPacket = require(ReplicatedStorage.shared.network.game.ClientboundCommandsPacket)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local dispatcher = CommandDispatcher.new()

--[=[
	@class CommandsClientPacketListener
]=]
local CommandsClientPacketListener = {}

function CommandsClientPacketListener.getDispatcher(): CommandDispatcher.CommandDispatcher<any>
	return dispatcher
end

TypedRemotes.ClientboundCommandsPacket.OnClientEvent:Connect(function(rootNode)
	dispatcher = CommandDispatcher.fromRoot(
		ClientboundCommandsPacket.deserializeFromNetwork(FriendlyByteBuf.fromBuffer(rootNode):toBuffer()):getRoot()
	)
end)

return CommandsClientPacketListener