--!strict

--[=[
	Behold my fucking madness.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArgumentType = require(ReplicatedStorage.shared.commands.arguments.ArgumentType)
local SharedSuggestionProvider = require(ReplicatedStorage.shared.commands.asymptote.suggestion.SharedSuggestionProvider)
local ArgumentTypeInfos = require(ReplicatedStorage.shared.commands.synchronization.arguments.ArgumentTypeInfos)
local SingletonArgumentInfo = require(ReplicatedStorage.shared.commands.synchronization.arguments.SingletonArgumentInfo)
local ArgumentCommandNode = require(ReplicatedStorage.shared.commands.tree.ArgumentCommandNode)
local CommandNode = require(ReplicatedStorage.shared.commands.tree.CommandNode)
local CommandNodeType = require(ReplicatedStorage.shared.commands.tree.CommandNodeType)
local LiteralCommandNode = require(ReplicatedStorage.shared.commands.tree.LiteralCommandNode)
local RootCommandNode = require(ReplicatedStorage.shared.commands.tree.RootCommandNode)
local FriendlyByteBuf = require(ReplicatedStorage.shared.network.FriendlyByteBuf)

type ArgumentCommandNode<S> = ArgumentCommandNode.ArgumentCommandNode<S>
type CommandNode<S> = CommandNode.CommandNode<S>
type FriendlyByteBuf = FriendlyByteBuf.FriendlyByteBuf
type LiteralCommandNode<S> = LiteralCommandNode.LiteralCommandNode<S>
type RootCommandNode<S> = RootCommandNode.RootCommandNode<S>
type SharedSuggestionProvider = SharedSuggestionProvider.SharedSuggestionProvider

type NodeStub = {
	name: string,
	parser: ArgumentType.ArgumentType<any>?,
	parserId: number?,
	template: SingletonArgumentInfo.Template?,
	suggestions: any?
}

type Entry = {
	stub: NodeStub,
	flags: number,
	redirect: number,
	children: {number}
}

local TYPE_ROOT = 0
local TYPE_LITERAL = 1
local TYPE_ARGUMENT = 2

local function enumerateNodes(
	root: RootCommandNode<SharedSuggestionProvider>
): ({ [CommandNode<SharedSuggestionProvider>]: number }, { CommandNode<SharedSuggestionProvider> })
	local nodeToIndex: {[CommandNode<SharedSuggestionProvider>]: number} = {}
	local nodesList: {CommandNode<SharedSuggestionProvider>} = {}

	local queue: {CommandNode<SharedSuggestionProvider>} = {root}
	local head = 1

	while head <= #queue do
		local currentNode = queue[head]
		head += 1

		if not nodeToIndex[currentNode] then
			local id = #nodesList
			nodeToIndex[currentNode] = id
			table.insert(nodesList, currentNode)

			for _, child in currentNode:getChildren() do
				table.insert(queue, child)
			end

			if currentNode:getRedirect()then
				table.insert(queue, currentNode:getRedirect())
			end
		end
	end

	return nodeToIndex, nodesList
end

local function createEntry(
	node: CommandNode<SharedSuggestionProvider>,
	nodeToIndex: {[CommandNode<SharedSuggestionProvider>]: number}
): Entry
	local flags = 0
	local redirectId = 0

	if node:getRedirect() then
		flags = bit32.bor(flags, 8)
		redirectId = nodeToIndex[node:getRedirect()]
	end

	if node:getCommand() ~= nil then
		flags = bit32.bor(flags, 4)
	end

	local stub: NodeStub?
	if node:getNodeType() == CommandNodeType.ROOT then
		flags = bit32.bor(flags, TYPE_ROOT)
	elseif node:getNodeType() == CommandNodeType.ARGUMENT then
		local argNode = (node :: any) :: ArgumentCommandNode<SharedSuggestionProvider>
		flags = bit32.bor(flags, TYPE_ARGUMENT)

		if argNode:getCustomSuggestions() ~= nil then
			flags = bit32.bor(flags, 16)
		end

		stub = {
			name = argNode:getName(),
			parser = argNode:getArgumentType(),
			parserId = ArgumentTypeInfos.getIdFromInstance(argNode:getArgumentType()),
			suggestions = argNode:getCustomSuggestions()
		}
	elseif node:getNodeType() == CommandNodeType.LITERAL then
		local literalNode = (node :: any) :: LiteralCommandNode<SharedSuggestionProvider>
		flags = bit32.bor(flags, TYPE_LITERAL)
		stub = {
			name = literalNode:getLiteral()
		}
	else
		error("Unknown node type:", node:getNodeType())
	end

	local childIds: {number} = {}
	for _, child in node:getChildren() do
		table.insert(childIds, nodeToIndex[child])
	end

	return {
		stub = stub,
		flags = flags,
		redirect = redirectId,
		children = childIds
	}
end

local function createEntries(
	nodeToIndex: {[CommandNode<SharedSuggestionProvider>]: number},
	nodesList: {CommandNode<SharedSuggestionProvider>}
): { [number]: Entry }
	local entries = {}

	for i, node in nodesList do
		local entry = createEntry(node, nodeToIndex)
		table.insert(entries, entry)
	end

	return entries
end

--

--[=[
	@class ClientboundCommandsPacket
]=]
local ClientboundCommandsPacket = {}
ClientboundCommandsPacket.__index = ClientboundCommandsPacket

export type ClientboundCommandsPacket = typeof(setmetatable({} :: {
	entries: { [number]: Entry },
	rootIndex: number
}, ClientboundCommandsPacket))

function ClientboundCommandsPacket.fromRootNode(root: RootCommandNode<SharedSuggestionProvider>): ClientboundCommandsPacket
	local nodeToIndex, nodesList = enumerateNodes(root)
	local entries = createEntries(nodeToIndex, nodesList)

	return setmetatable({
		entries = entries,
		rootIndex = nodeToIndex[root]
	}, ClientboundCommandsPacket)
end

function ClientboundCommandsPacket.getRoot(self: ClientboundCommandsPacket): RootCommandNode<SharedSuggestionProvider>
	local nodes: {CommandNode<SharedSuggestionProvider>} = {}

	for i, entry in self.entries do
		local nodeType = bit32.band(entry.flags, 3)
		if nodeType == TYPE_ROOT then
			nodes[i] = RootCommandNode.new()
		elseif nodeType == TYPE_LITERAL then
			nodes[i] = LiteralCommandNode.new(entry.stub.name)
		elseif nodeType == TYPE_ARGUMENT then
			local argType = entry.stub.template:instantiate()
			nodes[i] = ArgumentCommandNode.new(entry.stub.name, argType)
		end
	end

	for i, entry in self.entries do
		local currentNode = nodes[i]
		
		for _, childId in entry.children do
			currentNode:addChild(nodes[childId + 1])
		end

		if bit32.band(entry.flags, 8) ~= 0 then
			currentNode.redirect = nodes[entry.redirect + 1]
		end
	end

	return (nodes[self.rootIndex + 1] :: any) :: RootCommandNode<SharedSuggestionProvider>
end

function ClientboundCommandsPacket.serializeToNetwork(self: ClientboundCommandsPacket): buffer
	local buf = FriendlyByteBuf.new()

	buf:writeVarInt(#self.entries)

	for _, entry in self.entries do
		buf:writeByte(entry.flags)
		buf:writeVarInt(#entry.children)
		for _, childId in entry.children do
			buf:writeVarInt(childId)
		end

		if bit32.band(entry.flags, 8) ~= 0 then
			buf:writeVarInt(entry.redirect)
		end

		local nodeType = bit32.band(entry.flags, 3)

		if nodeType == TYPE_LITERAL then
			buf:writeUtf(entry.stub.name)
		elseif nodeType == TYPE_ARGUMENT then
			buf:writeUtf(entry.stub.name)
			local pId = entry.stub.parserId or 0
			buf:writeVarInt(pId)

			if pId > 0 then
				local info = ArgumentTypeInfos.byClass(entry.stub.parser)
				info.serializeToNetwork(buf, entry.stub.parser)
			end
		end
	end

	buf:writeVarInt(self.rootIndex)

	return buf:toBuffer()
end

function ClientboundCommandsPacket.deserializeFromNetwork(rbxBuffer: buffer): ClientboundCommandsPacket
	local buf = FriendlyByteBuf.fromBuffer(rbxBuffer)
	local entries: {Entry} = {}

	local nodeCount = buf:readVarInt()

	for i = 1, nodeCount do
		local flags = buf:readByte()
		
		local childCount = buf:readVarInt()
		local children = {}
		for j = 1, childCount do
			table.insert(children, buf:readVarInt())
		end

		local redirect = 0
		if bit32.band(flags, 8) ~= 0 then
			redirect = buf:readVarInt()
		end

		local nodeType = bit32.band(flags, 3)
		local stub: NodeStub? = nil

		if nodeType == TYPE_LITERAL then
			stub = {
				name = buf:readUtf()
			}
		elseif nodeType == TYPE_ARGUMENT then
			local name = buf:readUtf()
			local netId = buf:readVarInt()
			
			local template
			if netId > 0 then
				local info = ArgumentTypeInfos.byId(netId)
				template = info.deserializeFromNetwork(buf)
			end
			
			stub = {
				name = name,
				template = template
			}
		end

		table.insert(entries, {
			flags = flags,
			children = children,
			redirect = redirect,
			stub = stub
		})
	end

	local rootIndex = buf:readVarInt()

	return setmetatable({
		entries = entries,
		rootIndex = rootIndex
	}, ClientboundCommandsPacket)
end

return ClientboundCommandsPacket