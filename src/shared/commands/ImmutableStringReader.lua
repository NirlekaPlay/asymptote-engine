--!strict

export type ImmutableStringReader = {
	getString: (self: ImmutableStringReader) -> string,
	getRemainingLength: (self: ImmutableStringReader) -> number,
	getTotalLength: (self: ImmutableStringReader) -> number,
	getCursorPos: (self: ImmutableStringReader) -> number,
	getRead: (self: ImmutableStringReader) -> string,
	getRemaining: (self: ImmutableStringReader) -> string,
	canReadLength: (self: ImmutableStringReader, length: number) -> boolean,
	canRead: (self: ImmutableStringReader) -> boolean,
	peek: (self: ImmutableStringReader) -> string,
	peekOffset: (self: ImmutableStringReader, offset: number) -> string
}

return nil