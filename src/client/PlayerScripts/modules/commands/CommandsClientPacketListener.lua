--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local ArgumentTypeInfos = require(ReplicatedStorage.shared.commands.synchronization.arguments.ArgumentTypeInfos)
local ArgumentCommandNode = require(ReplicatedStorage.shared.commands.tree.ArgumentCommandNode)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local CommandNodeType = require(ReplicatedStorage.shared.commands.tree.CommandNodeType)
local LiteralCommandNode = require(ReplicatedStorage.shared.commands.tree.LiteralCommandNode)
local RootCommandNode = require(ReplicatedStorage.shared.commands.tree.RootCommandNode)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local function emptyFunc(): any
	return 
end

local function deserializeCommandNode(data: { [any]: any }): CommandNode.CommandNode<any>
	print(data)
	local entries = data.entries
	local nodes = {}

	-- This is a sin I know but its what I can think of today
	local function resolve(index: number)
		if nodes[index] then
			return nodes[index]
		end

		local entry = entries[index + 1] -- Handle 0-based vs 1-based
		local node: CommandNode.CommandNode<any>

		if entry.nodeType == CommandNodeType.LITERAL then
			node = LiteralCommandNode.new(entry.name, emptyFunc, emptyFunc, nil)
		elseif entry.nodeType == CommandNodeType.ARGUMENT then
			local argType = ArgumentTypeInfos.bySerializedTable(entry.argumentType)
				.deserializeFromTable(entry.argumentType):instantiate()
			node = ArgumentCommandNode.new(entry.name, argType, emptyFunc, emptyFunc, nil)
		else
			node = RootCommandNode.new()
		end

		nodes[index] = node

		if entry.redirect and entry.redirect ~= -1 then
			node.redirect = resolve(entry.redirect)
		end

		for _, childId in entry.children do
			local childNode = resolve(childId)
			if childNode.nodeType ~= CommandNodeType.ROOT then
				node:addChild(childNode)
			end
		end

		return node
	end

	return resolve(data.rootIndex)
end

local dispatcher = CommandDispatcher.new()

--[=[
	@class CommandsClientPacketListener
]=]
local CommandsClientPacketListener = {}

function CommandsClientPacketListener.getDispatcher(): CommandDispatcher.CommandDispatcher<any>
	return dispatcher
end

TypedRemotes.ClientboundCommandsPacket.OnClientEvent:Connect(function(rootNode)
	dispatcher = CommandDispatcher.fromRoot(deserializeCommandNode(rootNode))
end)

return CommandsClientPacketListener