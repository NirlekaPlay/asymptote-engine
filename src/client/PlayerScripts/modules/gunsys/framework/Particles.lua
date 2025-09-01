--!strict

local Debris = game:GetService("Debris")

local PARTICLE_ASSET_ID = "rbxassetid://375847957"
local PARTICLE_INST_NAME = "GunSysParticleEmitter"

--[=[
	@class Particles
]=]
local Particles = {}

function Particles.emitParticle(
	part: BasePart,
	color: Color3,
	minSize: number,
	maxSize: number,
	minLift: number,
	maxLift: number,
	speed: number, 
	emissionNormalEnum: Enum.NormalId,
	lifetime: number?
): ()
	-- In the original script, it calls the main logic
	-- with pcall. I don't know the purpose of it,
	-- and the original comment doesn't help much.
	-- But we haven't encountered any issues so far.
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Color = ColorSequence.new(color)
	particleEmitter.Texture = PARTICLE_ASSET_ID
	particleEmitter.Name = PARTICLE_INST_NAME
	particleEmitter.Drag = 10
	particleEmitter.EmissionDirection = emissionNormalEnum
	particleEmitter.Speed = NumberRange.new(speed)
	particleEmitter.Rate = 500
	particleEmitter.Lifetime = NumberRange.new(minLift,maxLift)
	particleEmitter.SpreadAngle = Vector2.new(-20,20)
	particleEmitter.Transparency = NumberSequence.new(0.75, 1)
	particleEmitter.Size = NumberSequence.new(minSize, maxSize)
	particleEmitter.Parent = part

	-- this is from the original script, which is kinda bad.
	-- though we keep this for now until we script a propper
	-- scheduler.
	task.spawn(function()
		-- this is to prevent the particle emitter texture
		-- from abruptly disappearing upon getting destroyed.
		task.wait(lifetime)
		particleEmitter.Enabled = false
		Debris:AddItem(particleEmitter, 0.5)
	end)
end

return Particles