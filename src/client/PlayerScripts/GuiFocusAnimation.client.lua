--!strict

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local RTween = require(script.Parent.modules.interpolation.RTween)

local currentCamera = workspace.CurrentCamera
local mainRtween = RTween.create(Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
mainRtween:set_parallel(true)

--local FOV_GAIN_PERCENTAGE = 25

local window_focused = true
local menu_open = false
local last_animation_played: {RTweenAnimation}? = nil

type RTweenAnimation = {
	instance: Instance,
	properties: RTween.PropertyParam | () -> RTween.PropertyParam,
	duration: number
}

local function instantiate(instanceName: string, parent: Instance, properties: { [string]: any }?): Instance
	local inst = Instance.new(instanceName) :: any
	if properties then
		for propertyName, propertyValue in pairs(properties) do
			inst[propertyName] = propertyValue
		end
	end
	inst.Parent = parent
	return inst
end

local EFFECTS_OBJECTS = {
	Blur = instantiate("BlurEffect", currentCamera, {Size = 0}),
	CC = instantiate("ColorCorrectionEffect", currentCamera),
	CCOcclude = instantiate("ColorCorrectionEffect", currentCamera)
}

local FOCUS_CHANGE_ANIMATIONS = {
	FOCUS_ACQUIRED = {
		{
			instance = EFFECTS_OBJECTS.Blur,
			properties = { Size = 0 },
			duration = .5
		},
		{
			instance = EFFECTS_OBJECTS.CC,
			properties = { Contrast = 0, Saturation = 0 },
			duration = .5
		},
		--[[{
			instance = currentCamera,
			properties = function()
				return { FieldOfView = currentCamera.FieldOfView * ( 1 + math.abs(FOV_GAIN_PERCENTAGE) / 100) }
			end,
			duration = 1
		},]]
	} :: {RTweenAnimation},
	FOCUS_RELEASED = {
		{
			instance = EFFECTS_OBJECTS.Blur,
			properties = { Size = 16 },
			duration = .5
		},
		{
			instance = EFFECTS_OBJECTS.CC,
			properties = { Contrast = 1, Saturation = -1 },
			duration = .5
		},
		--[[{
			instance = currentCamera,
			properties = function()
				local fovLoss = FOV_GAIN_PERCENTAGE
				if fovLoss > 0 then
					fovLoss = -fovLoss
				end
				return { FieldOfView = currentCamera.FieldOfView * ( 1 + fovLoss / 100) }
			end,
			duration = 1
		},]]
	} :: {RTweenAnimation}
}

local function animate(animations: { RTweenAnimation }): ()
	if mainRtween.is_playing then
		mainRtween:kill()
	end

	for _, animation in ipairs(animations) do
		local finalProperties: RTween.PropertyParam
		if typeof(animation.properties) == "table" then
			finalProperties = animation.properties
		else
			finalProperties = animation.properties()
		end
		mainRtween:tween_instance(animation.instance, finalProperties, animation.duration)
	end
	mainRtween:play()
end

local function onFocusChange()
	local animation
	if not menu_open and window_focused then
		animation = FOCUS_CHANGE_ANIMATIONS.FOCUS_ACQUIRED
	else
		animation = FOCUS_CHANGE_ANIMATIONS.FOCUS_RELEASED
	end

	if animation ~= last_animation_played then
		last_animation_played = animation
		animate(animation)
	end
end

if GuiService.MenuIsOpen then
	menu_open = true
	onFocusChange()
end

GuiService.MenuOpened:Connect(function()
	menu_open = true
	onFocusChange()
end)

GuiService.MenuClosed:Connect(function()
	menu_open = false
	onFocusChange()
end)

UserInputService.WindowFocused:Connect(function()
	window_focused = true
	onFocusChange()
end)

UserInputService.WindowFocusReleased:Connect(function()
	window_focused = false
	onFocusChange()
end)