--!strict

export type TypedAttribute<T> = {
	name: string
}

local function register<T>(name: string): TypedAttribute<T>
	return { name = name }
end

return {
	TRESPASSING_WARNS = register("Warns") :: TypedAttribute<number>,
	BEING_CONFRONTED_BY_UUID = register("BeingConfrontedByUuid") :: TypedAttribute<string>
}
