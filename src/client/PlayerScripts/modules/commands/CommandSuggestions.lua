--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArgumentTypeInfos = require(ReplicatedStorage.shared.commands.synchronization.ArgumentTypeInfos)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local TypedRemotes = require(ReplicatedStorage.shared.network.remotes.TypedRemotes)

local function deserializeCommandNode(data: { [any]: any }): CommandNode.CommandNode<any>
	local entries = data.entries
	local nodes = {}

	for i, entry in entries do
		local node
		if entry.nodeType == "literal" then
			node = CommandNode.new(entry.name, "literal")
		elseif entry.nodeType == "argument" then
			local argType = ArgumentTypeInfos.bySerializedTable(entry.argumentType).deserializeFromTable(entry.argumentType):instantiate()
			node = CommandNode.new(entry.name, "argument", argType)
		else
			node = CommandNode.new("", "")
		end
		nodes[i - 1] = node -- Match 0-based indexing cuz idfk anymore
	end

	for i, entry in entries do
		local node = nodes[i - 1]
		
		for _, childId in entry.children do
			node:addChild(nodes[childId])
		end

		if entry.redirect ~= -1 then
			node:redirect(nodes[entry.redirect])
		end
	end

	return nodes[data.rootIndex]
end

TypedRemotes.ClientboundCommandsPacket.OnClientEvent:Connect(function(rootNode)
	local deserializedRootNode = deserializeCommandNode(rootNode)
end)

return nil