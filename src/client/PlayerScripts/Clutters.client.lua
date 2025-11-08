--!strict

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local SurfaceText = require(StarterPlayer.StarterPlayerScripts.client.modules.ui.SurfaceText)

local CLUTTER_TAG_NAME = "Clutter"
local CLUTTER_PROP_ATTRIBUTE_NAME = "ClutterPropName"

local FLOAT_ATTRIBUTE_NAME = "Float"
local FLOAT_MAX_TILT_X_ATT_NAME = "MaxTiltX"
local FLOAT_MAX_TILT_Z_ATT_NAME = "MaxTiltZ"
local FLOAT_MAX_ROT_Y = "MaxRotY"
local FLOAT_SPEED_ATT_NAME = "FloatSpeed"

local rng = Random.new(os.clock())
--local clutterInstances: { [Instance]: true } = {}
local floatingClutters: { [Model | BasePart]: HoveringSpotlight } = {}

type HoveringSpotlight = {
	maxTiltX: number,
	maxTiltZ: number,
	maxRotationY: number,
	time: number,
	speed: number,
	baseCframe: CFrame,
	noiseOffset: Vector3
}

local function getAttributeOrDefault<T>(inst: Instance, attribute: string, default: T): T
	local get = inst:GetAttribute(attribute)
	if get == nil then
		return default
	else
		return get
	end
end

local function initialize(inst: Instance): ()
	if not inst:IsDescendantOf(workspace) then
		return
	end
	--clutterInstances[inst] = true
	local propName = inst:GetAttribute(CLUTTER_PROP_ATTRIBUTE_NAME)
	if not propName then
		return
	end

	if propName == "FloatingFlatText" and inst:IsA("BasePart") then
		SurfaceText.createFromPart(inst)
	end

	if (inst:IsA("Model") or inst:IsA("BasePart")) and inst:GetAttribute(FLOAT_ATTRIBUTE_NAME) == true then
		floatingClutters[inst] = {
			maxTiltX = getAttributeOrDefault(inst, FLOAT_MAX_TILT_X_ATT_NAME, 5),
			maxTiltZ = getAttributeOrDefault(inst, FLOAT_MAX_TILT_Z_ATT_NAME, 5),
			maxRotationY = getAttributeOrDefault(inst, FLOAT_MAX_ROT_Y, 10),
			time = 0,
			speed = getAttributeOrDefault(inst, FLOAT_SPEED_ATT_NAME, 0.5),
			baseCframe = if inst:IsA("Model") then inst:GetBoundingBox() else inst.CFrame,
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
	if inst:IsA("Model") and floatingClutters[inst] then
		floatingClutters[inst] = nil
	end
end)

RunService.PreRender:Connect(function(deltaTime)
	for clutter, object in pairs(floatingClutters) do

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

		if clutter:IsA("Model") then
			clutter:PivotTo(clutter:GetPivot():Lerp(targetCFrame, 0.1))
		else
			clutter.CFrame = clutter.CFrame:Lerp(targetCFrame, 0.1)
		end
	end
end)
