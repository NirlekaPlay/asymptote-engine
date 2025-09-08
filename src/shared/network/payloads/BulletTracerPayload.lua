--!strict

export type BulletTracer = {
	origin: Vector3,
	direction: Vector3,
	speed: number,
	size: number,
	penetration: number,
	humanoidRootPartVelocity: number,
	muzzleCframe: CFrame,
	seed: number
}

return nil