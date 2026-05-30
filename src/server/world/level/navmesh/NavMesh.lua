--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Node = require(ServerScriptService.server.ai.navigation.Node)

--[=[
	@class NavMesh
]=]
local NavMesh = {}
NavMesh.__index = NavMesh

export type NavMesh = typeof(setmetatable({} :: {
	registry: {[string]: Node.Node},
	groups: {[string]: {Node.Node}}
}, NavMesh))

function NavMesh.new(): NavMesh
	return setmetatable({
		registry = {},
		groups = {}
	}, NavMesh)
end

--

function NavMesh.getPostGroup(self: NavMesh, groupName: string): {Node.Node}
	return self.groups[groupName] or {}
end

--

function NavMesh.setPostsFromFolder(self: NavMesh, nodesFolder: Folder): ()
	table.clear(self.registry)
	table.clear(self.groups)

	local function registerFolder(folder: Folder, folderName: string): {Node.Node}
		local collected: {Node.Node} = {}

		for _, child in folder:GetChildren() do
			if child:IsA("BasePart") then
				local id = child:GetFullName()
				if not self.registry[id] then
					self.registry[id] = Node.new(child.CFrame)
				end
				table.insert(collected, self.registry[id])

			elseif child:IsA("Folder") then
				local childNodes = registerFolder(child, child.Name)
				for _, node in childNodes do
					table.insert(collected, node)
				end
			end
		end

		if not self.groups[folderName] then
			self.groups[folderName] = {}
		end

		for _, node in collected do
			table.insert(self.groups[folderName], node)
		end

		return collected
	end

	registerFolder(nodesFolder, nodesFolder.Name)
end

return NavMesh