--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)

export type Prop = {
	createFromPlaceholder: (placeholder: BasePart, model: Model?, serverLevel: ServerLevel.ServerLevel) -> Prop,
	onLevelRestart: (self: Prop) -> (),
	update: (self: Prop, deltaTime: number, serverLevel: ServerLevel.ServerLevel) -> ()
}

return nil