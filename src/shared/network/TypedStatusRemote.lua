--!nonstrict
--local ServerScriptService = game:GetService("ServerScriptService")

--local Statuses = require(ServerScriptService.server.player.Statuses)
-- FUCK YOU
export type PlayerStatus = "DISGUISED"
	| "MINOR_TRESPASSING"
	| "MINOR_SUSPICIOUS"
	| "MAJOR_TRESPASSING"
	| "CRIMINAL_SUSPICIOUS"
	| "DANGEROUS_ITEM"
	| "ARMED"

local TypedRemote = require("../thirdparty/TypedRemote")

local _, RE = TypedRemote.parent(script)

type RF<T..., R...> = TypedRemote.Function<T..., R...>
type RE<T...> = TypedRemote.Event<T...>

return RE("Status") :: RE<{ [PlayerStatus]: true }>