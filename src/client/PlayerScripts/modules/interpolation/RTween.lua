-- rtween.lua
-- NirlekaDev
-- April 27, 2025

--!strict

local TweenService = game:GetService("TweenService")

--[=[
	@class rtween

	The R stands for Roblox. It is a wrapper around TweenService,
	so it can be implemented in a way similar to Godot's Tween.
	Unlike the `src/modules/animation/tween` which uses an entirely custom
	implemention for tweening.

	This module was once part of the Dasar Standard Library.
]=]
local rtween = {}
rtween.__index = rtween

export type RTween = typeof(setmetatable({} :: {
	tweens: {Tween},
	stack: {{Tween}},
	connections: {RBXScriptConnection},
	easing_style: Enum.EasingStyle,
	easing_direction: Enum.EasingDirection,
	parallel_enabled: boolean,
	default_parallel: boolean,
	is_playing: boolean,
	is_paused: boolean,
	current_step: number
}, rtween))

export type PropertyParam = {
	[ string ] : any
}

local function append_tweens(self: RTween, tweens_arr: {Tween})
	local stack = self.stack
	local tweens = self.tweens
	local current_step_index = 0

	local stack_size = #stack
	if self.parallel_enabled then
		current_step_index = math.max(1, stack_size)
	else
		current_step_index = stack_size + 1
	end

	self.parallel_enabled = self.default_parallel

	if not stack[current_step_index] then
		table.insert(stack, {})
	end

	local current_step = stack[current_step_index]

	for _, tween in ipairs(tweens_arr) do
		table.insert(current_step, tween)
		table.insert(tweens, tween)
	end
end

local function clear_connections(connections: {RBXScriptConnection})
	for k, connection in ipairs(connections) do
		connection:Disconnect()
		connections[k] = nil
	end
end

local function play_step(self: RTween, step_index: number)
	if step_index > #self.stack then
		-- all steps completed
		self.current_step = 1
		self.is_playing = false
		return
	end

	self.current_step = step_index
	self.is_playing = true

	local step = self.stack[step_index]
	local step_size = #step
	local completed_tweens = 0

	for _, tween in ipairs(step) do
		tween:Play()

		local connection
		connection = tween.Completed:Once(function()
			completed_tweens += 1
			if completed_tweens == step_size then
				-- all tweens in this step are done
				if connection then
					connection:Disconnect()
				end

				play_step(self, step_index + 1) -- move to next step
			end
		end)

		table.insert(self.connections, connection)
	end
end

function rtween.create(
	easing_style: Enum.EasingStyle,
	easing_direction: Enum.EasingDirection
): RTween
	local self = {
		tweens = {},
		stack = {},
		connections = {},
		easing_style = easing_style or Enum.EasingStyle.Linear,
		easing_direction = easing_direction or Enum.EasingDirection.InOut,
		parallel_enabled = false,
		default_parallel = false,
		is_playing = false,
		is_paused = false,
		current_step = 1
	}

	return setmetatable(self, rtween)
end

function rtween.play(self: RTween)

	-- I should probably tell you how the Stack works.
	-- The Stack holds references to the tweens table,
	-- The Stack contains 'steps' which itself contains the actual tweens.
	-- In each step, all tweens inside will play at the same time.
	-- In order to advance to the next step, all tweens in the current step
	-- has to be completed.

	local is_paused = self.is_paused -- to make the typechecker stfu on line 142
	if self.is_playing and not is_paused then
		return
	end

	clear_connections(self.connections)

	self.is_paused = false -- YEAH, TAKE THAT

	play_step(self, if self.is_paused then self.current_step else 1)
end

function rtween.kill(self: RTween)
	for k, tween in ipairs(self.tweens) do
		tween:Cancel()
		tween:Destroy()
		self.tweens[k] = nil
	end

	local stack = self.stack
	for k, step in ipairs(stack) do
		table.clear(step)
	end
	table.clear(stack)

	clear_connections(self.connections)

	self.current_step = 1
	self.is_playing = false
	self.is_paused = false
end

function rtween.parallel(self: RTween)
	self.parallel_enabled = true
end

function rtween.pause(self: RTween)
	self.is_paused = true

	for k, tween in ipairs(self.tweens) do
		tween:Pause()
	end
end

function rtween.set_parallel(self: RTween, parallel: boolean)
	self.default_parallel = true
	self.parallel_enabled = true
end

function rtween.tween_instance(
	self: RTween,
	inst: Instance,
	properties: PropertyParam,
	dur: number,
	delay: number?,
	easing_style: Enum.EasingStyle?,
	easing_direction: Enum.EasingDirection?
)
	local tween_info = TweenInfo.new(
		dur,
		easing_style or self.easing_style,
		easing_direction or self.easing_direction,
		0,
		false,
		delay or 0
	)
	local tweens_arr = {}

	for prop_name, prop_fnl_val in pairs(properties) do
		local tween_inst = TweenService:Create(
			inst,
			tween_info,
			{ [prop_name] = prop_fnl_val }
		)
		table.insert(tweens_arr, tween_inst)
	end

	append_tweens(self, tweens_arr)
end

return rtween