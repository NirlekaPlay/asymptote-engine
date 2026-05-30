--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Prop = require(ServerScriptService.server.world.level.props.Prop)
local PropHandler = require(ServerScriptService.server.world.level.props.registry.PropHandler)
local Scene = require(ServerScriptService.server.world.level.scene.Scene)

--[=[
	@class PropHandlerBuilder
]=]
local PropHandlerBuilder = {}
PropHandlerBuilder.__index = PropHandlerBuilder

export type PropHandlerBuilder = typeof(setmetatable({} :: {
	onProccessFunc: ProccessorFunc?
}, PropHandlerBuilder))

type ProccessorFunc = (placeholder: BasePart, prop: Model?, scene: Scene.Scene) -> (boolean, Prop.Prop?)

function PropHandlerBuilder.new(): PropHandlerBuilder
	return setmetatable({
		onProccessFunc = nil :: ProccessorFunc?
	}, PropHandlerBuilder)
end

--

function PropHandlerBuilder.onProccess(self: PropHandlerBuilder, fn: ProccessorFunc): PropHandlerBuilder
	self.onProccessFunc = fn
	return self
end

function PropHandlerBuilder.build(self: PropHandlerBuilder): PropHandler.PropHandler
	if not self.onProccessFunc then
		error("No proccess function!")
	end

	local f = self.onProccessFunc

	return {
		proccess = function(_, ...)
			return f(...)
		end
	}
end

return PropHandlerBuilder