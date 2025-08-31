--!strict

export type PerceptiveAgent = {
	getSightRadius: (self: PerceptiveAgent) -> number,
	getHearingRadius: (self: PerceptiveAgent) -> number,
	getPeripheralVisionAngle: (self: PerceptiveAgent) -> number,
}

return nil