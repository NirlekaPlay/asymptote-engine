--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local DetectionDummy = require(ServerScriptService.server.npc.dummies.DetectionDummy)

export type EntityType<T> = {
	name: string
}

local function register(entityName: string): EntityType<any>
	return {
		name = entityName
	}
end

return {
	NPC_DETECTION_DUMMY = register("DetectionDummy") :: EntityType<DetectionDummy.DummyAgent>,
	DEAD_BODY = register("DeadBody")
}