--!strict

--[=[
	Defines an interface for a type of Agent who can detect suspicious activity.
]=]
export type DetectionAgent = {
	character: Model,
	canDetectThroughDisguises: (self: DetectionAgent) -> boolean
}

return nil