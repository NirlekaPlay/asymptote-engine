--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

--[=[
	@class MouseManager
]=]
local MouseManager = {}

local NO_MOUSE_LOCK_IN_STUDIO = true

local mouseDefaultLocked = if NO_MOUSE_LOCK_IN_STUDIO and RunService:IsStudio() then false else true
local mouseLocked = mouseDefaultLocked
local mouseDefaultIconEnabled = if NO_MOUSE_LOCK_IN_STUDIO and RunService:IsStudio() then true else false
local mouseIconEnabled = mouseDefaultIconEnabled
local mouseUnusableOverrides: { [string]: true } = {}

local function isDevConsoleVisible(): boolean
	local success, value = pcall(function()
		return StarterGui:GetCore("DevConsoleVisible")
	end)

	return success and value
end

function MouseManager.addUnuseableMouseOverride(name: string): ()
	mouseUnusableOverrides[name] = true
end

function MouseManager.removeUnuseableMouseOverride(name: string): ()
	mouseUnusableOverrides[name] = nil
end

function MouseManager.setLockEnabled(locked: boolean): ()
	if locked and RunService:IsStudio() then
		return
	end
	mouseDefaultLocked = locked
	mouseLocked = locked
end

function MouseManager.setIconEnabled(enabled: boolean): ()
	if not enabled and RunService:IsStudio() then
		return
	end
	mouseDefaultIconEnabled = enabled
	mouseIconEnabled = enabled
end

function MouseManager.update(): ()
	local isConsoleVisible = isDevConsoleVisible()
	if isConsoleVisible or next(mouseUnusableOverrides) ~= nil then
		mouseIconEnabled = true
		mouseLocked = false
	else
		mouseIconEnabled = mouseDefaultIconEnabled
		mouseLocked = mouseDefaultLocked
	end

	if mouseLocked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	elseif NO_MOUSE_LOCK_IN_STUDIO and RunService:IsStudio() then -- For some reason you cant move the camera correctly with RMB.
		return
	else
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end

	if mouseIconEnabled then
		if not UserInputService.MouseIconEnabled then
			UserInputService.MouseIconEnabled = true
		end
	else
		UserInputService.MouseIconEnabled = false
	end
end

return MouseManager