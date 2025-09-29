--!strict

export type ArgumentType = {
	parse: (input: string) -> (any, number) -- returns (value, charactersConsumed)
}

return nil