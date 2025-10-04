--!strict

--[=[
	An argument parser that returns a value of type `T` and the amount of
	characters it has consumed after parsing.
]=]
export type ArgumentType<T> = {
	parse: (self: ArgumentType<T>, input: string) -> (T, number) -- returns (value, charactersConsumed)
}

return nil