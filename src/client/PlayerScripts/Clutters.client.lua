--!strict

local CLUTTER_TAG_NAME = "Clutter"
local CLUTTER_PROP_ATTRIBUTE_NAME = "ClutterPropName"
local CLUTTER_HOVERING_SPOTLIGHT_PROP_NAME = "Spotlight"
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local rng = Random.new(os.clock())
local clutterInstances: { [Instance]: true } = {}
local hoveringSpotlightsInstances: { [Model]: HoveringSpotlight } = {}

type HoveringSpotlight = {
	maxTiltX: number,
	maxTiltZ: number,
	maxRotationY: number,
	time: number,
	speed: number,
	baseCframe: CFrame,
	noiseOffset: Vector3
}

local function initialize(inst: Instance): ()
	clutterInstances[inst] = true
	local propName = inst:GetAttribute(CLUTTER_PROP_ATTRIBUTE_NAME)
	if not propName then
		return
	end

	if propName == CLUTTER_HOVERING_SPOTLIGHT_PROP_NAME and inst:IsA("Model") then
		hoveringSpotlightsInstances[inst] = {
			maxTiltX = 5,
			maxTiltZ = 5,
			maxRotationY = 10,
			time = 0,
			speed = 0.5,
			baseCframe = inst:GetBoundingBox(),
			noiseOffset = Vector3.new(
				rng:NextNumber(0, 1000),
				rng:NextNumber(0, 1000),
				rng:NextNumber(0, 1000)
			)
		}
	end
end

for _, inst in ipairs(CollectionService:GetTagged(CLUTTER_TAG_NAME)) do
	initialize(inst)
end

CollectionService:GetInstanceAddedSignal(CLUTTER_TAG_NAME):Connect(function(inst)
	initialize(inst)
end)

CollectionService:GetInstanceRemovedSignal(CLUTTER_TAG_NAME):Connect(function(inst)
	if inst:IsA("Model") and hoveringSpotlightsInstances[inst] then
		hoveringSpotlightsInstances[inst] = nil
	end
end)

RunService.PreRender:Connect(function(deltaTime)
	for spotlight, object in pairs(hoveringSpotlightsInstances) do

		object.time = (object.time + deltaTime * object.speed) % 1000 -- prevents it for accumulating over time
		local time = object.time

		local o = object.noiseOffset
		local x = math.noise(time + o.X, o.Y, o.Z) * 5
		local y = math.noise(o.X, time + o.Y, o.Z) * 3
		local z = math.noise(o.X, o.Y, time + o.Z) * 5

		local rotX = math.noise(time + 100 + o.X, o.Y, o.Z) * object.maxTiltX
		local rotY = math.noise(o.X, time + 100 + o.Y, o.Z) * object.maxRotationY
		local rotZ = math.noise(o.X, o.Y, time + 100 + o.Z) * object.maxTiltZ


		local targetCFrame = CFrame.new(object.baseCframe.Position + Vector3.new(x, y, z)) * 
			object.baseCframe.Rotation *
			CFrame.Angles(
				math.rad(rotX),
				math.rad(rotY),
				math.rad(rotZ)
			)

		spotlight:PivotTo(spotlight:GetPivot():Lerp(targetCFrame, 0.1))
	end
end)
