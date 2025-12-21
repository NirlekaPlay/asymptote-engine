--!nocheck

local SmoothDamp = require(script.Parent.SmoothDamp)

local SmoothValue = {}
SmoothValue.__index = SmoothValue

function SmoothValue.new(vec3: Vector3, smoothTime: number)
	assert(typeof(vec3) == "Vector3", "initialValue should be Vector3")
	assert(typeof(smoothTime) == "number", "smoothTime should be a number")
	assert(smoothTime >= 0, "smoothTime must be a positive number")

	local v2 = setmetatable({
		Value = vec3, 
		Goal = vec3,
		SmoothTime = smoothTime
	}, SmoothValue)
	v2._smoothDamp = SmoothDamp.new()
	return v2
end

function SmoothValue.Update(p3, p4)
	if p4 then
		p3.Goal = p4
	else
		p4 = p3.Goal
	end

	local v3 = p3._smoothDamp:Update(p3.Value, p4, p3.SmoothTime)
	p3.Value = v3

	return v3
end

function SmoothValue.UpdateAngle(p5, p6)
	if p6 then
		p5.Goal = p6
	else
		p6 = p5.Goal
	end
	local v4 = p5._smoothDamp:UpdateAngle(p5.Value, p6, p5.SmoothTime)
	p5.Value = v4
	return v4
end

function SmoothValue.SetMaxSpeed(p7, p8)
	p7._smoothDamp.MaxSpeed = p8
end

function SmoothValue.GetMaxSpeed(p9)
	return p9._smoothDamp.MaxSpeed
end

return SmoothValue :: any