--!nonstrict

local TypedRemote = require("../thirdparty/TypedRemote")

local _, RE = TypedRemote.parent(script)

type RF<T..., R...> = TypedRemote.Function<T..., R...>
type RE<T...> = TypedRemote.Event<T...>

return RE("BubbleChat") :: RE<BasePart, string>