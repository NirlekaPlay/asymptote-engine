--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Prop = require(ServerScriptService.server.world.level.props.Prop)

local DEFAULT_UPDATES_PER_SEC = 1 / 20

--[=[
	@class PropManager
]=]
local PropManager = {}
PropManager.__index = PropManager

export type PropManager = typeof(setmetatable({} :: {
	nextId: number,
	props: { [number]: Prop.Prop }
}, PropManager))

function PropManager.new(): PropManager
	return setmetatable({
		nextId = 1,
		props = {}
	}, PropManager)
end

--

function PropManager.addProp(self: PropManager, prop: Prop.Prop): number
	local id = self.nextId + 1
	self.nextId = id
	prop.id = id
	self.props[id] = prop
	return id
end

function PropManager.getPropById(self: PropManager, id: number)
	return self.props[id]
end

function PropManager.restartProps(self: PropManager): ()
	for _, prop in self.props do
		if prop.restart then
			prop:restart()
		end
	end
end

function PropManager.destroyAllProps(self: PropManager): ()
	for _, prop in self.props do
		if prop.destroy then
			prop:destroy()
		end
	end

	table.clear(self.props)
	self.nextId = 1
end

--

function PropManager.update(self: PropManager, deltaTime: number): ()
	debug.profilebegin("update_props")

	for _, prop in self.props do
		if not prop.update then
			continue
		end

		local ups = prop.updatesPerSec or DEFAULT_UPDATES_PER_SEC

		prop._elapsed = (prop._elapsed or 0) + deltaTime

		if prop._elapsed >= ups then
			prop:update(prop._elapsed)
			prop._elapsed = 0
		end
	end

	debug.profileend()
end

return PropManager