--!strict

export type LocalTweenPayload = {
	tweenInfo: SerializedTweenInfo,
	instance: Instance,
	properties: { [any]: any }
}

export type SerializedTweenInfo = {
	time: number?,
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?,
	repeatCount: number?,
	reverses: boolean?,
	delayTime: number?
}

return nil