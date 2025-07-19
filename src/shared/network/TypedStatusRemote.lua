--!nonstrict
--local ServerScriptService = game:GetService("ServerScriptService")

--local Statuses = require(ServerScriptService.server.player.Statuses)
-- FUCK YOU
export type PlayerStatus =
	"MINOR_TRESPASSING"
	| "MAJOR_TRESPASSING"
	| "MINOR_SUSPICIOUS"
	| "CRIMINAL_SUSPICIOUS"
	| "DISGUISED"
	| "ARMED"
local TypedRemote = require("../thirdparty/TypedRemote")

local _, RE = TypedRemote.parent(script)

type RF<T..., R...> = TypedRemote.Function<T..., R...>
type RE<T...> = TypedRemote.Event<T...>

return RE("Status") :: RE<{ [PlayerStatus]: true }>