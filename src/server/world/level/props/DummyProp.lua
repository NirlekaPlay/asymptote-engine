--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Prop = require(ServerScriptService.server.world.level.props.Prop)

--[=[
	@class DummyProp

	Provides you the boilerplate for functional props.
]=]
local DummyProp = {}
DummyProp.__index = DummyProp

type Self = Prop.Fields & {

}

export type DummyProp = Prop.Prop & typeof(setmetatable({} :: Self, DummyProp))

function DummyProp.new(id: number): DummyProp
	local self: Self = {
		id = id,
		updatesPerSec = nil :: number?,
		_elapsed = 0
	}

	return (setmetatable(self, DummyProp) :: any) :: DummyProp
end

--

function DummyProp.update(self: DummyProp, deltaTime: number): ()
	return
end

function DummyProp.restart(self: DummyProp): ()
	return
end

function DummyProp.destroy(self: DummyProp): ()
	return
end

return DummyProp