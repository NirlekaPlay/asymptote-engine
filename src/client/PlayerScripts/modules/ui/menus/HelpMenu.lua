--!strict

local isEnabled = false

--[=[
	@class HelpMenu
]=]
local HelpMenu = {}

function HelpMenu.isEnabled(): boolean
	return isEnabled
end

function HelpMenu.setIsEnabled(bool: boolean): ()
	isEnabled = bool
end

return HelpMenu