--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Prop = require(ServerScriptService.server.world.level.props.Prop)
local Scene = require(ServerScriptService.server.world.level.scene.Scene)

export type PropHandler = {
	proccess: (self: PropHandler, placeholder: BasePart, prop: Model?, scene: Scene.Scene) -> (boolean, Prop.Prop?)
}

return nil