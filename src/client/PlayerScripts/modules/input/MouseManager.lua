--!strict

local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

--[=[
	@class MouseManager
]=]
local MouseManager = {}

local mouseDefaultLocked = true
local mouseLocked = mouseDefaultLocked
local mouseDefaultIconEnabled = false
local mouseIconEnabled = mouseDefaultIconEnabled
local mouseUnusableOverrides: { [string]: true } = {}

function MouseManager.addUnuseableMouseOverride(name: string): ()
	mouseUnusableOverrides[name] = true
end

function MouseManager.removeUnuseableMouseOverride(name: string): ()
	mouseUnusableOverrides[name] = nil
end

function MouseManager.setLockEnabled(locked: boolean): ()
	mouseDefaultLocked = locked
	mouseLocked = locked
end

function MouseManager.setIconEnabled(enabled: boolean): ()
	mouseDefaultIconEnabled = enabled
	mouseIconEnabled = enabled
end

function MouseManager.update(): ()
	local isConsoleVisible = StarterGui:GetCore("DevConsoleVisible") :: boolean
	if isConsoleVisible or next(mouseUnusableOverrides) ~= nil then
		mouseIconEnabled = true
		mouseLocked = false
	else
		mouseIconEnabled = mouseDefaultIconEnabled
		mouseLocked = mouseDefaultLocked
	end

	if mouseLocked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	if mouseIconEnabled then
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseIconEnabled = false
	end
end

return MouseManager