--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldPointer = require("./modules/gui/WorldPointer")
local RTween = require("./modules/interpolation/RTween")

type MeterGui = {
	main_gui: Frame,
	background_meter: ImageLabel,
	seperator: CanvasGroup,
	fill_meter: ImageLabel
}

type MeterObject = {
	comp_pointer: WorldPointer.WorldPointer,
	meter_gui: MeterGui,
	last_sus: number,
	current_RTween: RTween.RTween,
	is_raising: boolean,
	do_rotate: boolean
}

local ALERTED_SOUND = ReplicatedStorage.shared.assets.sounds.temp_undertale_alert
local REMOTE = require(ReplicatedStorage.shared.network.TypedDetectionRemote)
local DETECTION_GUI = Players.LocalPlayer.PlayerGui:WaitForChild("Detection")
local FRAME_METER_REF = DETECTION_GUI.SusMeter

local active_meters: { [Model]: MeterObject } = {}

local function clone_meter_frame(): Frame
	local cloned = FRAME_METER_REF:Clone() :: any -- use any so the typechecker will stfu
	cloned.Visible = true
	cloned.Frame.CanvasGroup.A1.ImageTransparency = 1
	cloned.Frame.A1.ImageTransparency = 1
	cloned.Visible = true
	cloned.Parent = DETECTION_GUI
	return cloned
end

local function create_meter_gui_object(gui: Frame): MeterGui
	local frame = gui:FindFirstChild("Frame") :: Frame
	local canvas = frame:FindFirstChild("CanvasGroup") :: CanvasGroup
	return {
		main_gui = gui,
		background_meter = frame:FindFirstChild("A1") :: ImageLabel,
		seperator = canvas,
		fill_meter = canvas:FindFirstChild("A1") :: ImageLabel
	}
end

local function create_meter_object(origin: Vector3): MeterObject
	local new_gui_inst = clone_meter_frame()
	return {
		comp_pointer = WorldPointer.create(new_gui_inst, origin),
		meter_gui = create_meter_gui_object(new_gui_inst),
		last_sus = 0,
		current_RTween = RTween.create(Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		is_raising = false,
		do_rotate = true
	}
end

RunService.RenderStepped:Connect(function()
	for _, meter in pairs(active_meters) do
		if not meter.do_rotate then
			continue
		end

		WorldPointer.update(meter.comp_pointer)
	end
end)

REMOTE.OnClientEvent:Connect(function(sus_value: number, id: Model, origin: Vector3)
	local current_meter = active_meters[id]
	local exists = current_meter ~= nil
	if not exists then
		local new_gui = create_meter_object(origin)
		active_meters[id] = new_gui
		new_gui.current_RTween:set_parallel(true)
		current_meter = new_gui -- HOW ARE YOU THIS FUCKING RETARDED, TYPECHECKER?!
	end

	local cur_meter_gui = current_meter.meter_gui :: MeterGui -- WHEN THE TYPECHECKER IS SO FUCKING RETARDED THAT IT CANT EVEN ACCESS METER GUI CUZ OF THE `current_meter = new_gui` FUCKER
	local cur_tween = current_meter.current_RTween :: RTween.RTween -- OH NOW ITS TYPE NEVER?!??! ARE YOU FUCKING RETARDED?!??!

	if sus_value == 1 then
		local udim_pos = cur_meter_gui.main_gui.Position
		local rotation_deg = cur_meter_gui.main_gui.Rotation
		local distance = 30

		local rotation_rad = math.rad(rotation_deg - 90) -- idk why but subtracting it with 90 fixes the direction
		local direction = Vector2.new(math.cos(rotation_rad), math.sin(rotation_rad))

		local x_offset = udim_pos.X.Offset + direction.X * distance
		local y_offset = udim_pos.Y.Offset + direction.Y * distance

		udim_pos = UDim2.new(udim_pos.X.Scale, x_offset, udim_pos.Y.Scale, y_offset)

		if cur_tween.is_playing then
			(cur_tween :: RTween.RTween):kill() -- FYM TRUE??!?!?! THIS SHIT AINT A BOOLEAN YOU CUNT
		end
		current_meter.do_rotate = false -- due to the meter constantly rotating, tweening it up while rotating can make it rotate weirdly. so a lazy solution to this is to not rotate it.
		cur_tween:tween_instance(cur_meter_gui.background_meter, {ImageTransparency = 1}, .3)
		cur_tween:tween_instance(cur_meter_gui.fill_meter, {ImageTransparency = 1}, .3)
		cur_tween:tween_instance(cur_meter_gui.main_gui, {Position = udim_pos}, .3)
		cur_tween:tween_instance(cur_meter_gui.fill_meter, {ImageColor3 = Color3.new(1, 0, 0)}, .3)
		cur_tween:play()
		ALERTED_SOUND:Play()
		return
	else
		current_meter.do_rotate = true
	end

	local clamped_sus = math.clamp(sus_value, 0, 1) -- keeps the sus_value between 0 and 1
	current_meter.comp_pointer.target_pos = origin
	cur_meter_gui.seperator.Size = UDim2.fromScale(clamped_sus, 1)

	if sus_value > current_meter.last_sus then
		cur_meter_gui.fill_meter.ImageColor3 = Color3.new(1, 1, 1)
		current_meter.is_raising = true
	elseif sus_value < current_meter.last_sus then
		cur_meter_gui.fill_meter.ImageColor3 = Color3.new(0.509804, 0.509804, 0.509804)
		current_meter.is_raising = false
	end

	(function()
		if current_meter.is_raising then
			if not (sus_value < 0.5) then
				return
			end
			if cur_tween then
				cur_tween:kill()
			end
			cur_tween:tween_instance(cur_meter_gui.fill_meter, {ImageTransparency = 0}, .3)
			cur_tween:tween_instance(cur_meter_gui.background_meter, {ImageTransparency = 0.5}, .3) -- makes the back a lil bit transparent
			cur_tween:play()
		else
			if not (sus_value < 0.5) then
				return
			end
			if cur_tween.is_playing then
				(cur_tween :: RTween.RTween):kill() -- ISTG ITS NOT A BOOLEAN YOU BASTARD
			end
			cur_tween:tween_instance(cur_meter_gui.fill_meter, {ImageTransparency = 1}, .5)
			cur_tween:tween_instance(cur_meter_gui.background_meter, {ImageTransparency = 1}, .5)
			cur_tween:play()
		end
	end)()

	current_meter.last_sus = sus_value
end)