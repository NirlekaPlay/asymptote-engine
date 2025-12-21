--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)

local worldListeners: { [SoundListener]: true } = {}

--[=[
	@class SoundSimulation
]=]
local SoundSimulation = {}

export type SoundListener = {
	getPosition: (self: SoundListener) -> Vector3,
	getMinHearingDist: (self: SoundListener) -> number,
	checkListener: (self: SoundListener, pos: Vector3, attenuatedIntensity: number) -> ()
}

export type SoundProfile = {
	BaseIntensity: number, -- Starting "Loudness"
	MaxDistance: number,   -- Maximum physical travel distance in studs
	Falloff: string        -- TODO: "Linear" or "Logarithmic"
}

local SoundRegistry: {[string]: SoundProfile} = {
	Footstep = {
		BaseIntensity = 10,
		MaxDistance = 10,
		Falloff = "Linear"
	},
	Shout = {
		BaseIntensity = 50,
		MaxDistance = 80,
		Falloff = "Linear"
	},
	Gunshot = {
		BaseIntensity = 100,
		MaxDistance = 300,
		Falloff = "Linear"
	},
	SuppressedGunshot = {
		BaseIntensity = 60,
		MaxDistance = 120,
		Falloff = "Linear"
	},
	Explosion = {
		BaseIntensity = 500,
		MaxDistance = 600,
		Falloff = "Linear"
	}
}

local SystemConfig = {
	MaxReflections = 2,
	MinAudibleThreshold = 1, -- If intensity drops below this, the sound is effectively "gone"
	GlobalDifficultyMult = 1.0 -- Use this to scale all ranges (e.g., 1.2 for Hard Mode)
}

local function getMaterialProperties(tag: Enum.Material): {absorption: number, reflection: number}
	if tag == Enum.Material.Concrete or tag == Enum.Material.Metal then
		return { absorption = 0.1, reflection = 0.8 }
	elseif tag == Enum.Material.Wood then
		return { absorption = 0.2, reflection = 0.6 }
	elseif tag == Enum.Material.Carpet or tag == Enum.Material.Fabric then
		return { absorption = 0.8, reflection = 0.1 }
	else 
		return { absorption = 0.05, reflection = 0.0 }
	end
end

local function qFibonacciSphere(samples: number): {Vector3}
	local points: {Vector3} = {}
	local phi = math.pi * (math.sqrt(5) - 1)

	for i = 1, samples do
		local y = 1 - (i / (samples - 1)) * 2
		local radius = math.sqrt(1 - y * y)
		local theta = phi * i
		local x = math.cos(theta) * radius
		local z = math.sin(theta) * radius
		table.insert(points, Vector3.new(x, y, z))
	end

	return points
end

function SoundSimulation.addListener(listener: SoundListener): ()
	worldListeners[listener] = true
end

function SoundSimulation.removeListener(listener: SoundListener): ()
	worldListeners[listener] = nil
end

function SoundSimulation.emitSound(origin: Vector3, soundName: string, ignoreList: {Instance}?): ()
	local profile = SoundRegistry[soundName]
	if not profile then
		warn("Sound Profile not found:", soundName)
		return
	end

	-- Setup Raycast Params to ignore the source of the sound (e.g., the player or gun model)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignoreList or {}
	rayParams.IgnoreWater = true

	-- TODO: Lower sample count for quiet sounds, higher for loud ones?
	local directions = qFibonacciSphere(32) 

	for _, direction in ipairs(directions) do
		SoundSimulation.traceRay(
			origin, 
			direction, 
			profile.BaseIntensity, -- Start with defined loudness
			0, -- Distance traveled starts at 0
			0, -- Reflections start at 0
			profile, -- Pass the configuration object
			rayParams
		)
	end
end

function SoundSimulation.traceRay(
	origin: Vector3, 
	direction: Vector3, 
	currentIntensity: number, 
	totalDistanceTraveled: number,
	reflections: number,
	profile: SoundProfile,
	rayParams: RaycastParams
): ()

	-- Determine how much range this specific sound has left
	local adjustedMaxRange = profile.MaxDistance * SystemConfig.GlobalDifficultyMult
	local remainingRange = adjustedMaxRange - totalDistanceTraveled
	
	-- If we have no range left, or intensity is too low, stop.
	if remainingRange <= 0 or currentIntensity < SystemConfig.MinAudibleThreshold then
		return
	end

	-- Cast the ray only as far as the sound can theoretically reach
	local result = workspace:Raycast(origin, direction * remainingRange, rayParams)

	if result then
		Draw.line(origin, result.Position)
		
		-- Calculate distance for this specific segment
		local segmentDistance = (result.Position - origin).Magnitude
		local newTotalDistance = totalDistanceTraveled + segmentDistance
		
		local materialTag = result.Material
		local properties = getMaterialProperties(materialTag)

		-- ATTENUATION CALCULATION
		-- Formula: Intensity decreases based on % of max distance traveled + material absorption
		local distanceRatio = newTotalDistance / adjustedMaxRange
		local attenuatedIntensity = profile.BaseIntensity * (1 - distanceRatio)
		
		-- Apply material absorption immediately upon impact
		attenuatedIntensity = attenuatedIntensity * (1 - properties.absorption)

		for listener in worldListeners do
			if (listener:getPosition() - result.Position).Magnitude > listener:getMinHearingDist() then
				continue
			end

			listener:checkListener(result.Position, attenuatedIntensity)
		end
		
		-- REFLECTION CHECK
		if reflections < SystemConfig.MaxReflections and attenuatedIntensity > SystemConfig.MinAudibleThreshold then
			local reflectedIntensity = attenuatedIntensity * properties.reflection

			if reflectedIntensity > SystemConfig.MinAudibleThreshold then
				-- Calculate reflection vector
				local newDirection = direction - 2 * (direction:Dot(result.Normal)) * result.Normal
				
				-- Offset the origin slightly to prevent the ray from hitting the same wall immediately
				local reflectionOrigin = result.Position + (result.Normal * 0.1)

				SoundSimulation.traceRay(
					reflectionOrigin, 
					newDirection, 
					reflectedIntensity, 
					newTotalDistance, -- Pass accumulated distance
					reflections + 1,
					profile,
					rayParams
				)
			end
		end

	else
		-- Ray Missed: Sound travels freely to the end of its range
		Draw.raycast(origin, direction * remainingRange)
		
		local endPoint = origin + (direction * remainingRange)
		
		-- Calculate final intensity at the max range (usually near 0, but useful for 'open air' checks)
		local finalIntensity = profile.BaseIntensity * 0.1 -- Small residual value for open air
		
		-- print("Sound dissipated at:", endPoint, "Final Intensity:", finalIntensity)
	end
end

return SoundSimulation