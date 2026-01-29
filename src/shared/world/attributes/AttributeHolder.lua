--!strict

export type AttributeHolder = {
	getAttribute: (self: AttributeHolder, name: string) -> any
}

return nil